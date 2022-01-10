# Artifact
You can simply test the benchmarks used in the [paper](https://conf.researchr.org/details/icse-2022/icse-2022-papers/147/SymTuner-Maximizing-the-Power-of-Symbolic-Execution-by-Adaptively-Tuning-External-Pa) by following the instructions.
All experiments are tested with Ubuntu 18.04 LTS.

## Quickstart
You can see and coverage graph and bug report of testing gcal-4.1 with following commands:
```bash
# you need some requirements; see Benchmarks/Requirements section
$ ./make-paper-benchmark.sh gcal-4.1
$ symtuner --output-dir SymTuner gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
$ symtuner --search-space hand-crafted-parameters.json --output-dir Default_Short gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
# you need matplotlib, pandas, and tabulate to run report.py; see Visualize section
$ python3 report.py SymTuner Default_Short --name gcal-4.1
# see coverage.pdf and bugs.md
```

## Benchmarks
SymTuner offers easy-to-use benchmark compilation script.
The available benchmark list is as follows:
* combine-0.4.0
* diff-3.7 (from diffutils-3.7)
* du-8.32 (from coreutils-8.32)
* enscript-1.6.6
* gawk-5.1.0
* gcal-4.1
* grep-3.4
* ls-8.32 (from coreutils-8.32)
* nano-4.9
* sed-4.8
* trueprint-5.4
* xorriso-1.5.2

### Requirments
The script requires some additional libraries to build project. The following command will install requirements:
```bash
$ sudo apt-get update
$ sudo apt-get install -y --no-install-recommends build-essential clang-6.0 curl file libcap-dev libncurses5-dev llvm-6.0 llvm-6.0-dev llvm-6.0-tools python3 python3-pip python3-setuptools
$ sudo pip3 install --no-cache-dir wllvm
# You need to set PATH to clang and llvm binarys
$ export PATH=/usr/lib/llvm-6.0/bin:$PATH
# Now you can use ./make-paper-benchmark.sh
$ ./make-paper-benchmark.sh ...
```

### Benchmark Build
The provided script (`make-paper-benchmark.sh`) will help you download and build the benchmarks.
For example, if you want to build `combine-0.4.0` and `gcal-4.1` use the following command:
```bash
$ ./make-paper-benchmark.sh combine-0.4.0 gcal-4.1
```
The script offers `all` options to build all 12 benchmarks.

If you want to run testing for a single benchmark in parallel, you need to make multiple objects.
For example, the following command will make 3 objects for `combine-0.4.0` and `gcal-4.1`:
```bash
$ ./make-paper-benchmark.sh --n-objs 3 combine-0.4.0 gcal-4.1
```

If you need further infomation use `--help` option:
```bash
$ ./make-paper-benchmark.sh --help
```

### Your Own Benchmark
Compile LLVM bytecode. Compile GCov support executable.

## Test Benchmark
This section assume that SymTuner is installed.
If you have not installed yet, please follow the instructions at [here](https://github.com/skkusal/symtuner).
You can test the gcal with default settings with the following commands:
```bash
$ ./make-paper-benchmarks gcal-4.1  # build gcal-4.1
$ symtuner gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
```
All benchmarks can be run with default settings, except for whom that mentioned in [Notes](#Notes).

### Notes
There are some benchmarks that needs more options.

#### Test One Program In Parallel
To test one program in parellel, you need to use different objects for each process.
`make-paper-benchmark.sh` offers `--n-objs` options to create multiple objects at once.
For example, if you want to test gcal-4.1 with 2 different settings, you may use the following commands:
```bash
$ ./make-paper-benchmark.sh --n-objs 2 gcal-4.1
# your first setting
$ symtuner --output-dir symtuner-out gcal-4.1/obj-llvm1/src/gcal.bc gcal-4.1/obj-gcov1/src/gcal
# your second setting
$ symtuner --search-space hand-crafted-parameters.json --output-dir default-out gcal-4.1/obj-llvm2/src/gcal.bc gcal-4.1/obj-gcov2/src/gcal
```

#### No Optimize
Some benchmarks failed to execute with `-optimize` option.
Therefore, `-optimize` option needs to be removed to test the following benchmarks:
* gawk-5.1.0
* trueprint-5.4

`space-without-optimize.json` is a default parameter space setting with `-optimize` option removed.
You can directry use it to test those benchmarks:
```bash
$ symtuner --search-space space-without-optimize.json trueprint-5.4/obj-llvm/src/trueprint.bc trueprint-5.4/obj-gcov/src/trueprint
```

#### GCov Depth Adjustment
All executables in benchmarks provided, except for gawk-5.1.0, located in the 1 level depth of folder from the root.
However, gawk-5.1.0 executable located in the root directory, so `--gcov-depth` should be set as 0:
```bash
# --search-space option is explained in No Optimize section
$ symtuner --search-space space-without-optimize.json --gcov-depth 0 gawk-5.1.0/obj-llvm/gawk.bc gawk-5.1.0/obj-gcov/gawk
```

### Testing without Tuning
To test without tuning, you can give SymTuner an empty tuning space (which is defined with `"space"` key in a json file).
`hand-crafted-parameters.json` gives some default parameters that can be used to test benchmarks without tuning:
```bash
$ cat hand-crafted-parameters.json
{
    "space": {},
    "defaults": {
        "-output-module": "false",
...
# run symtuner only with pre-defined parameters
$ symtuner --search-space hand-crafted-parameters.json --output-dir default-out gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
```

## Visualize
`report.py` is a visualization script that generate a coverage graph over time and a table of found bugs.
The script need some requirments, and you can install the requirements with the followng command:
```bash
$ sudo pip3 install matplotlib pandas tabulate
```
You can compare multiple results by passing the result directories generated by SymTuner:
```bash
$ python3 report.py result1 result2 ...
```
You can see some parameters (e.g. the title of the graph) by passing `--help` option.
