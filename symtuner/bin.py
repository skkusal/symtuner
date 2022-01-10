'''Module that defines console script entries

This module that defines consol script entries. This module includes console script entry
for SymTuner for KLEE.
'''

from pathlib import Path
import argparse
import json
import shutil
import sys

from symtuner.klee import KLEE
from symtuner.klee import KLEESymTuner
from symtuner.logger import get_logger
from symtuner.symtuner import TimeBudgetHandler


def main(argv=None):
    '''Main entry for console script for SymTuner for KLEE

    Main entry for consol script for SymTuner for KLEE.

    Args:
        argv: A list of arguments. By default, use the system arguments except for
            the first element.
    '''

    if argv == None:
        argv = sys.argv[1:]

    # Commandline argument parser
    parser = argparse.ArgumentParser()

    # Executable settings
    executable = parser.add_argument_group('executable settings')
    executable.add_argument('--klee', default='klee', type=str,
                            help='path to "klee" executable (default=klee)')
    executable.add_argument('--klee-replay', default='klee-replay', type=str,
                            help='path to "klee-replay" executable (default=klee-replay)')
    executable.add_argument('--gcov', default='gcov', type=str,
                            help='path to "gcov" executable (default=gcov)')

    # Hyperparameters
    hyperparameters = parser.add_argument_group('hyperparameters')
    hyperparameters.add_argument('-t', '--budget', default=3600, type=int, metavar='INT',
                                 help='time budget in seconds (default=3600)')
    hyperparameters.add_argument('--minimum-time-portion', default=0.005, type=float, metavar='FLOAT',
                                 help='minimum portion for one iteration (default=0.005)')
    hyperparameters.add_argument('--minimum-time-budget', default=30, type=int, metavar='INT',
                                 help='strict minimum time budget for testing (default=30)')
    hyperparameters.add_argument('--round', default=20, type=int, metavar='INT',
                                 help='steps before increasing time budget (default=20)')
    hyperparameters.add_argument('--increase-ratio', default=2, type=float, metavar='FLOAT',
                                 help='multiplier for next time budget (default=2)')
    hyperparameters.add_argument('-s', '--search-space', default=None, type=str, metavar='JSON',
                                 help='json file defining parameter search space')
    hyperparameters.add_argument('--exploit-portion', default=0.7, type=float, metavar='FLOAT',
                                 help='portion of exploitation in SymTuner (default=0.7)')
    hyperparameters.add_argument('--k-seeds', default=10, type=int, metavar='INT',
                                 help='number of seeds for search spece to collect in terms of coverage (default=10)')
    hyperparameters.add_argument('--warmup-rounds', default=20, type=int, metavar='INT',
                                 help='exploring rounds in start (default=20)')

    # Others
    parser.add_argument('--output-dir', default='symtuner-out', type=str,
                        help='directory for generated files (default=symtuner-out)')
    parser.add_argument('--generate-search-space-json', action='store_true',
                        help='make example json file defining parameter search space')
    parser.add_argument('--debug', action='store_true',
                        help='log debug messages')
    parser.add_argument('--gcov-depth', default=1, type=int,
                        help='depth to search for gcda and gcov files from gcov_obj (default=1)')

    # Target
    required = parser.add_argument_group('required arguments')
    required.add_argument('llvm_bc', nargs='?', default=None,
                          help='LLVM bitecode file for klee')
    required.add_argument('gcov_obj', nargs='?', default=None,
                          help='executable with gcov support')

    args = parser.parse_args(argv)

    if args.debug:
        get_logger().setLevel('DEBUG')

    if args.generate_search_space_json:
        space_json = KLEESymTuner.get_default_space_json()
        with Path('example-space.json').open('w') as stream:
            json.dump(space_json, stream, indent=4)
            get_logger().info('Example space configuration json is generated: example-space.json')
        sys.exit(0)

    if args.llvm_bc is None or args.gcov_obj is None:
        parser.print_usage()
        print('following parameters are required: llvm_bc, gcov_obj')
        sys.exit(1)

    output_dir = Path(args.output_dir)
    if output_dir.exists():
        shutil.rmtree(str(output_dir))
        get_logger().warning('Existing output directory is deleted: '
                             f'{output_dir}')
    output_dir.mkdir(parents=True)
    coverage_csv = output_dir / 'coverage.csv'
    coverage_csv.touch()
    get_logger().info(
        f'Coverage will be recoreded at "{coverage_csv}" at every iteration.')
    found_bugs_txt = output_dir / 'found_bugs.txt'
    found_bugs_txt.touch()
    get_logger().info(
        f'Found bugs will be recoreded at "{found_bugs_txt}" at every iteration.')

    # Initialize Symbolic Executor
    symbolic_executor = KLEE(args.klee)

    # Initialize SymTuner
    symtuner = KLEESymTuner(args.klee_replay, args.gcov, args.k_seeds,
                            args.search_space, args.exploit_portion)
    evaluation_argument = {'folder_depth': args.gcov_depth}

    # Do until timeout
    get_logger().info('All configuration loaded. Start testing.')
    time_budget_handler = TimeBudgetHandler(args.budget, args.minimum_time_portion,
                                            args.round, args.increase_ratio,
                                            args.minimum_time_budget)
    for i, time_budget in enumerate(time_budget_handler):

        iteration_dir = output_dir / f'iteration-{i}'

        # Sample parameters
        policy = 'explore' if i < args.warmup_rounds else None
        parameters = symtuner.sample(policy=policy)

        # Run symbolic executor
        parameters[symbolic_executor.get_time_parameter()] = time_budget
        parameters['-output-dir'] = str(iteration_dir)
        testcases = symbolic_executor.run(args.llvm_bc, parameters)

        # Collect result
        symtuner.add(args.gcov_obj, parameters, testcases, evaluation_argument)

        elapsed = time_budget_handler.elapsed
        coverage, bugs = symtuner.get_coverage_and_bugs()
        get_logger().info(f'Iteration: {i + 1} '
                          f'Time budget: {time_budget} '
                          f'Time elapsed: {elapsed} '
                          f'Coverage: {len(coverage)} '
                          f'Bugs: {len(bugs)}')
        with coverage_csv.open('a') as stream:
            stream.write(f'{elapsed}, {len(coverage)}\n')
        with found_bugs_txt.open('w') as stream:
            stream.writelines((f'Testcase: {Path(symtuner.get_testcase_causing_bug(bug)).absolute()} '
                               f'Bug: {bug}\n' for bug in bugs))

    coverage, bugs = symtuner.get_coverage_and_bugs()
    get_logger().info(f'SymTuner done. Achieve {len(coverage)} coverage '
                      f'and found {len(bugs)} bugs.')
