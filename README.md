# SymTuner
[SymTuner](https://conf.researchr.org/details/icse-2022/icse-2022-papers/147/SymTuner-Maximizing-the-Power-of-Symbolic-Execution-by-Adaptively-Tuning-External-Pa) is a tool that automatically **tunes external parameters of symbolic execution** via online learning. This tool is implemented on the top of [KLEE](https://klee.github.io), a publicly available symbolic execution tool for testing C programs. For more technical details, please read our paper which will be published at [ICSE'22](https://conf.researchr.org/home/icse-2022).

## Installation
### Docker Image
We provide a [docker](https://www.docker.com) image that all requirements are pre-installed at [skkusal/symtuner](https://hub.docker.com/repository/docker/skkusal/symtuner). 
To install [docker](https://www.docker.com) on your system, please follow the instructions at [docker installation](https://docs.docker.com/engine/install). 
After the [docker](https://www.docker.com) is successfully installed, you can download and use our tool by following the commands below:
```bash
$ docker pull skkusal/symtuner
$ docker run --rm -it --ulimit='stack=-1:-1' skkusal/symtuner
```
Since KLEE, the symbolic executor, needs a big stack size,
we recommend you to set an unlimited stack size by `--ulimit='stack=-1:-1'`.

## Usage
You can check the options of SymTuner with the following command:
```
$ symtuner -h
usage: symtuner [-h] [--klee KLEE] [--klee-replay KLEE_REPLAY] [--gcov GCOV]
                [-t INT] [--minimum-time-portion FLOAT] [--round INT]
                [--increase-ratio FLOAT] [-s JSON] [--exploit-portion FLOAT]
                [--k-seeds INT] [--warmup-rounds INT]
                [--output-dir OUTPUT_DIR] [--generate-search-space-json]
                [--debug] [--gcov-depth GCOV_DEPTH]
                [llvm_bc] [gcov_obj]
...
```

### Two mandatory options
**Two options** are mandatory to run SymTuner; 
the first one is an LLVM bitcode file to run KLEE, and the second one is an executable file with Gcov instrumentation to calculate coverage.
| Option | Description |
|:------:|:------------|
| `llvm_bc` | LLVM bitcode file |
| `gcov_obj` | executable with Gcov support |

<!--
Besides, you may carefully pass the depth of parent directory to collect auxilary files for Gcov.
You can set the level as the depth to the root of the target object.
| Option | Description |
|:------:|:------------|
| `--gcov-depth` | The parent depth to find gcov auxilary files, such as `*.gcda` and `*.gcov` files |
-->

### Hyperparameters
Here are some important hyperparameters. You may see all hyperparameters by passing `--help` option to SymTuner.
| Option | Description |
|:------:|:------------|
| `--budget` | Total time budget |
| `--search-space` | Path to json file that defines parameter spaces |

If you do not specify search space, SymTuner will use the parameter spaces predefined in our paper.
You can give your own parameter space with `--search-space` option.
`--generate-search-space-json` option will generate an example json that defines search spaces:
```bash
$ symtuner --generate-search-space-json
# See example-space.json
```

In the json file, there are two entries;
`space` for paramters to be tuned by SymTuner, and `defaults` for parameters to use directly without tuning.
```
{
    "space": {
        "-max-memory": [[500, 1000, 1500, 2000, 2500], 1],
        "-sym-stdout": [["on", "off"], 1],
        ...
    },
    "defaults": {
        "-watchdog": null,
        ...
    }
}
```
Each tuning space is defined by its candidate values, and the maximum number of times to be repeated.

## Artifact
Here, we provide an instruction to conduct a short experiment that performs **KLEE+SymTuner** and **KLEE with default parameters**, respectively, on a benchmark program **gcal-4.1** once with a time budget of one hour. 
Note that, conducting experiments on all benchmarks (Figure 3 in our paper) takes a total of 1,920 hours (12 benchmarks * 10 hours * 4 baselines * 4 iterations). 

### Benchmarks
We offer all benchmarks used for our experiments in `/workspaces` directory:
```bash
$ docker run --rm -it --ulimit='stack=-1:-1' skkusal/symtuner
/workspaces$ ls
combine-0.4.0   diffutils-3.7   gawk-5.1.0  grep-3.4    sed-4.8         xorriso-1.5.2
coreutils-8.32  enscrip-1.6.6   gcal-4.1    nano-4.9    trueprint-5.4
```
All benchmarks have already been compiled, so these can be tested via SymTuner directly. 

### Running KLEE with SymTuner.
You can perform **KLEE+SymTuner** on the program **gcal-4.1** with the following command:
```bash
/workspaces$ symtuner -t 3600 -s spaces.json --dir KLEE_SymTuner gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal 
```
Then, you will see the testing progress as follows:
```bash
...
2022-01-10 14:08:26 symtuner [INFO] All configuration loaded. Start testing.
2022-01-10 14:09:03 symtuner [INFO] Iteration: 1 Time budget: 30 Time elapsed: 36 Coverage: 1125 Bugs: 0
2022-01-10 14:09:40 symtuner [INFO] Iteration: 2 Time budget: 30 Time elapsed: 73 Coverage: 1144 Bugs: 0
2022-01-10 14:10:17 symtuner [INFO] Iteration: 3 Time budget: 30 Time elapsed: 111 Coverage: 1395 Bugs: 0
...

```
When SymTuner successfully terminates, you can see the following output:
```bash
...
2022-01-10 15:08:55 symtuner [INFO] SymTuner done. Achieve 2756 coverage and found 1 bug.
```

### Running KLEE with default parameters.
You can also perform **KLEE** with the default parameter values without SymTuner as the following command:
```bash
/workspaces$ symtuner -t 3600 -s no-tuning.json --dir defaultKLEE gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
```
Then, you will see the process similar to the above testing process of symtuner.

### Visualizing the experimental results.
`report.py` is a visualization script that generates a coverage graph over time and a table of found bugs.
This script needs some requirments, and you can install the requirements with the followng command:
```bash
$ sudo pip3 install matplotlib pandas tabulate
```
The script takes the directories generated by running **KLEE+SymTuner** and **KLEE with default parameters**, repectively, and compares the experimental results as:
```bash
$ python3 report.py KLEE_SymTuner defaultKLEE
```

Then, you can see the coverage graph of the experimental results at `coverage.pdf`:
![gcal-coverage-image](./image/gcal_coverage.png)

You can also find the bug table at `bugs.md`:
```
/workspaces$ cat bugs.md
# Bug Table for gcal-4.1
|                              |  KLEE_SymTuner  |  defaultKLEE  |
|-----------------------------:|:---------------:|:-------------:|
|      ../../src/file-io.c 740 |        V        |       X       |
```

## Contribution
We are welcome any issues. Please, leave them in the [Issues](https://github.com/skkusal/symtuner/issues) tab.

### Implement Your Own Idea
If you want to make any contribution, plesase use the [devcontainer](https://code.visualstudio.com/docs/remote/containers) settings of SymTuner with all requirements pre-installed.
You can set up the environment with a few steps as follows:
1. Install [Visual Studio Code](https://code.visualstudio.com/).
2. Install [Docker](https://www.docker.com/). You can find installation instructions for each platforms at [here](https://docs.docker.com/engine/install/).
3. Install [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extention. Open extension bar (`CTRL + Shift + X` or `CMD + Shift + X`), search `Remote - Containers`, and install it.
4. Clone this repository (or a forked repository), and open it with VSCode.
```bash
$ git clone https://github.com/skkusal/symtuner.sal # or clone a forked repository
$ code symtuner
```
5. Press `F1`, and run `Reopen In Container`.
6. Now, you can implement and test your own idea!
7. (Optional) Install SymTuner in editable mode to test your idea simultaneously with the VSCode terminal (<code>CTRL + &#96;</code>).
```bash
# Note that this command should be typed in the terminal inside VSCode, not your own terminal application
/workspaces/symtuner$ [sudo] pip3 install -e .
```

## Citation
You can cite our paper, if you use our work with your own work.
```
@inproceddings{symtuner,
    author={Cha, Sooyoung and Lee, Myungho and Lee, Seokhyun and Oh, Hakjoo},
    booktitle={2022 IEEE/ACM 43rd International Conference on Software Engineering (ICSE)}, 
    title={SymTuner: Maximizing the Power of Symbolic Execution by Adaptively Tuning External Parameters},
    year={2022}
}
```
