# SymTuner
[SymTuner](https://conf.researchr.org/details/icse-2022/icse-2022-papers/147/SymTuner-Maximizing-the-Power-of-Symbolic-Execution-by-Adaptively-Tuning-External-Pa) is a tool that automatically **tunes external parameters of symbolic execution** via online learning. This tool is implemented on the top of [KLEE](https://klee.github.io), a publicly available symbolic execution tool for testing C programs. For more technical details, please read our paper which will be published at [ICSE'22](https://conf.researchr.org/home/icse-2022).

## Installation
### Docker Image
We provide a [docker](https://www.docker.com) image that all requirements are pre-installed at [skkusal/symtuner](https://hub.docker.com/repository/docker/skkusal/symtuner). 
To install [docker](https://www.docker.com) on your system, please follow the instructions at [docker installation](https://docs.docker.com/engine/install). 
After [docker](https://www.docker.com) is successfully installed, you can download and use our tool by following the commands below:
```bash
$ docker pull skkusal/symtuner
$ docker run --rm -it --ulimit='stack=-1:-1' skkusal/symtuner
```
Since KLEE, the symbolic executor, needs a big stack size,
we recommend you to set an unlimited stack size by `--ulimit='stack=-1:-1'`.

## Artifact
Here, we provide an example instruction which conducts a short experiment performing **KLEE+SymTuner** and **KLEE with default parameters**, respectively, on a benchmark program **gcal-4.1** once with a time budget of one hour. 
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
/workspaces$ symtuner -t 3600 -s spaces.json -d KLEE_SymTuner gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal 
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
/workspaces$ symtuner -t 3600 -s no-tuning.json -d defaultKLEE gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
```
Then, you will see the process similar to the above testing process of symtuner.

### Visualizing the experimental results.
`report.py` is a visualization script that generates a coverage graph over time and a table of found bugs.
This script needs some requirements, and you can install the requirements with the following command:
```bash
$ sudo pip3 install matplotlib pandas tabulate
```
The script takes the directories generated by running **KLEE+SymTuner** and **KLEE with default parameters**, respectively, and compares the experimental results as:
```bash
$ python3 report.py KLEE_SymTuner defaultKLEE --name gcal-4.1
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

### Commands for All Benchmarks
Click to see commands for each benchmark:

<details>
<summary>combine-0.4.0</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d combine_SymTuner combine-0.4.0/obj-llvm/src/combine.bc combine-0.4.0/obj-gcov/src/combine 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d combine_defaultKLEE combine-0.4.0/obj-llvm/src/combine.bc combine-0.4.0/obj-gcov/src/combine
# Visualize
$ python3 report.py combine_SymTuner combine_defaultKLEE --name combine-0.4.0
```

</div>
</details>
<details>
<summary>diff-3.7 (from diffutils-3.7)</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d diff_SymTuner diffutils-3.7/obj-llvm/src/diff.bc diffutils-3.7/obj-gcov/src/diff 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d diff_defaultKLEE diffutils-3.7/obj-llvm/src/diff.bc diffutils-3.7/obj-gcov/src/diff
# Visualize
$ python3 report.py diff_SymTuner diff_defaultKLEE --name diff-3.7
```

</div>
</details>
<details>
<summary>du-8.32 (from coreutils-8.32)</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d du_SymTuner coreutils-8.32/obj-llvm/src/du.bc coreutils-8.32/obj-gcov/src/du 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d du_defaultKLEE coreutils-8.32/obj-llvm/src/du.bc coreutils-8.32/obj-gcov/src/du
# Visualize
$ python3 report.py du_SymTuner du_defaultKLEE --name du-8.32
```

</div>
</details>
<details>
<summary>enscript-1.6.6</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d enscript_SymTuner enscript-1.6.6/obj-llvm/src/enscript.bc enscript-1.6.6/obj-gcov/src/enscript 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d enscript_defaultKLEE enscript-1.6.6/obj-llvm/src/enscript.bc enscript-1.6.6/obj-gcov/src/enscript
# Visualize
$ python3 report.py enscript_SymTuner enscript_defaultKLEE --name enscript-1.6.6
```

</div>
</details>
<details>
<summary>gawk-5.1.0</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s no-optimize.json -d gawk_SymTuner --gcov-depth 0 gawk-5.1.0/obj-llvm/gawk.bc gawk-5.1.0/obj-gcov/gawk 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d gawk_defaultKLEE --gcov-depth 0 gawk-5.1.0/obj-llvm/gawk.bc gawk-5.1.0/obj-gcov/gawk
# Visualize
$ python3 report.py gawk_SymTuner gawk_defaultKLEE --name gawk-5.1.0
```

</div>
</details>
<details>
<summary>gcal-4.1</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d gcal_SymTuner gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d gcal_defaultKLEE gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
# Visualize
$ python3 report.py gcal_SymTuner gcal_defaultKLEE --name gcal-4.1
```

</div>
</details>
<details>
<summary>grep-3.4</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d grep_SymTuner grep-3.4/obj-llvm/src/grep.bc grep-3.4/obj-gcov/src/grep 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d grep_defaultKLEE grep-3.4/obj-llvm/src/grep.bc grep-3.4/obj-gcov/src/grep
# Visualize
$ python3 report.py grep_SymTuner grep_defaultKLEE --name grep-3.4
```

</div>
</details>
<details>
<summary>ls-8.32 (from coreutils-8.32)</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d ls_SymTuner coreutils-8.32/obj-llvm/src/ls.bc coreutils-8.32/obj-gcov/src/ls 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d ls_defaultKLEE coreutils-8.32/obj-llvm/src/ls.bc coreutils-8.32/obj-gcov/src/ls
# Visualize
$ python3 report.py ls_SymTuner ls_defaultKLEE --name ls-8.32
```

</div>
</details>
<details>
<summary>nano-4.9</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d nano_SymTuner nano-4.9/obj-llvm/src/nano.bc nano-4.9/obj-gcov/src/nano 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d nano_defaultKLEE nano-4.9/obj-llvm/src/nano.bc nano-4.9/obj-gcov/src/nano
# Visualize
$ python3 report.py nano_SymTuner nano_defaultKLEE --name nano-4.9
```

</div>
</details>
<details>
<summary>sed-4.8</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d sed_SymTuner sed-4.8/obj-llvm/src/sed.bc sed-4.8/obj-gcov/src/sed 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d sed_defaultKLEE sed-4.8/obj-llvm/src/sed.bc sed-4.8/obj-gcov/src/sed
# Visualize
$ python3 report.py sed_SymTuner sed_defaultKLEE --name sed-4.8
```

</div>
</details>
<details>
<summary>trueprint-5.4</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s no-optimize.json -d trueprint_SymTuner trueprint-5.4/obj-llvm/src/trueprint.bc trueprint-5.4/obj-gcov/src/trueprint 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d trueprint_defaultKLEE trueprint-5.4/obj-llvm/src/trueprint.bc trueprint-5.4/obj-gcov/src/trueprint
# Visualize
$ python3 report.py trueprint_SymTuner trueprint_defaultKLEE --name trueprint-5.4
```

</div>
</details>
<details>
<summary>xorriso-1.5.2</summary>
<div markdown="1">

```bash
# Run SymTuner
$ symtuner -t 3600 -s spaces.json -d xorriso_SymTuner xorriso-1.5.2/obj-llvm/src/xorriso.bc xorriso-1.5.2/obj-gcov/src/xorriso 
# Run default KLEE
$ symtuner -t 3600 -s no-tuning.json -d xorriso_defaultKLEE xorriso-1.5.2/obj-llvm/src/xorriso.bc xorriso-1.5.2/obj-gcov/src/xorriso
# Visualize
$ python3 report.py xorriso_SymTuner xorriso_defaultKLEE --name xorriso-1.5.2
```

</div>
</details>


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
You can also see the meaning of each option of SymTuner as:
```
$ symtuner --help
...
optional arguments:
  -h, --help            show this help message and exit
  --output-dir OUTPUT_DIR
                        directory for generated files (default=symtuner-out)                     
...
```

### Two mandatory options
**Two options** are mandatory to run SymTuner: **llvm_bc** and **gcov_obj**. 
**llvm_bc** indicates a location of an LLVM bitcode file to run KLEE, and **gcov_obj** is a location of an executable file with Gcov instrumentation for coverage calculation.
| Option | Description |
|:------:|:------------|
| `llvm_bc` | LLVM bitcode file |
| `gcov_obj` | executable with Gcov support |

<!--
Besides, you may carefully pass the depth of parent directory to collect auxiliary files for Gcov.
You can set the level as the depth to the root of the target object.
| Option | Description |
|:------:|:------------|
| `--gcov-depth` | The parent depth to find gcov auxiliary files, such as `*.gcda` and `*.gcov` files |
-->

### Hyperparameters
Here are some important hyperparameters. You can check all hyperparameters by passing `--help` option to SymTuner.
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
`space` for parameters to be tuned by SymTuner, and `defaults` for parameters to use directly without tuning.
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



## Source Code Structure
Here are breif descriptions of files. Some less-important files may omitted.
```
.
├── benchmarks                  Some auxilary files for testing provided benchmarks
└── symtuner                    Main source code directory
    ├── bin.py                  CLI command entry point
    ├── klee.py                 KLEE specific implementation of SymTuner
    ├── logger.py               Logging module
    ├── symbolic_executor.py    Interface for all symbolic executors (e.g., KLEE)
    └── symtuner.py             Core algorithm of SymTuner
```
You can see the detailed descriptions of source codes in each file.

## Contribution
We are welcome any issues. Please, leave them in the [Issues](https://github.com/skkusal/symtuner/issues) tab.

### Implement Your Own Idea
If you want to make any contribution, please use the [devcontainer](https://code.visualstudio.com/docs/remote/containers) settings of SymTuner with all requirements pre-installed.
You can set up the environment with a few steps as follows:
1. Install [Visual Studio Code](https://code.visualstudio.com/).
2. Install [Docker](https://www.docker.com/). You can find installation instructions for each platforms at [here](https://docs.docker.com/engine/install/).
3. Install [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension. Open extension bar (`CTRL + Shift + X` or `CMD + Shift + X`), search `Remote - Containers`, and install it.
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
