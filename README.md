# SymTuner
[SymTuner](https://conf.researchr.org/details/icse-2022/icse-2022-papers/147/SymTuner-Maximizing-the-Power-of-Symbolic-Execution-by-Adaptively-Tuning-External-Pa) is an online parameter tuning tool for symbolic executors which is publised at [ICSE'22](https://conf.researchr.org/home/icse-2022).
Currently, SymTuner is developed based on [KLEE](https://klee.github.io).

## Docker
We offer a [docker](https://www.docker.com) image that all requirements are pre-installed at [skkusal/symtuner](https://hub.docker.com/repository/docker/skkusal/symtuner).
You can download and use it if you installed docker in your machine:
```bash
$ docker pull skkusal/symtuner
```
To run a container use the following command.
Note that, since KLEE which is a testing tool called by SymTuner internally needs a big stack size,
you may need to set an unlimited stack size by `--ulimit='stack=-1:-1'` to avoid stack overflow issues inside a container:
```bash
$ docker run --rm -it --ulimit='stack=-1:-1' skkusal/symtuner
```
If you have not installed docker yet, you may see [here](https://docs.docker.com/engine/install), or follow instructions in the next section to install SymTuner directly.

### Benchmarks
Inside the container, we offer benchmarks in `/workspaces` directory:
```bash
$ docker run --rm -it --ulimit='stack=-1:-1' skkusal/symtuner
/workspaces$ ls
combine-0.4.0   diffutils-3.7   gawk-5.1.0  grep-3.4    sed-4.8         xorriso-1.5.2
coreutils-8.32  enscrip-1.6.6   gcal-4.1    nano-4.9    trueprint-5.4
```
All benchmarks are compiled and can be directly tested. For example, you can test gcal-4.1 with the following command:
```bash
/workspaces$ symtuner gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
```
You can see the detailed instructions about testing the provided benchmarks in [artifact](./artifact).

## Local Installation
If you want to build your own environment, you can install SymTuner with your machine directly.

### Requirements
SymTuner is tested with the following dependencies with Ubuntu 18.04 LTS.
* KLEE 2.0
* GCov 7.5.0
* Python 3.6

You can install KLEE 2.0 by following instructions at [here](https://klee.github.io/releases/docs/v2.0/build-llvm60/).
Ohter dependencies can be installed with the following commands:
```bash
$ sudo apt-get update
$ sudo apt-get install gcc python3 python3-pip
```

### Installation
You can easily install SymTuner with `pip`:
```bash
$ sudo pip3 install git+https://github.com/skkusal/symtuner.git@v0.1.0
```

## Usage
You can see a usage message of SymTuner with the following command:
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
Important options you may interested in will be explained.
All options can be found with `--help` option.

### Target
Options to set the target program to test. These options are **required**.
SymTuner needs 2 different objects; first is object complied with LLVM, and second is object with GCov support.
| Option | Description |
|:------:|:------------|
| `llvm_bc` | Object that compiled with LLVM |
| `gcov_obj` | Object that compiled with GCov support |

Besides, you may carefully pass the depth of parent directory to collect auxilary files for GCov.
You can set the level as the depth to the root of the target object.
| Option | Description |
|:------:|:------------|
| `--gcov-depth` | The parent depth to find gcov auxilary files, such as `*.gcda` and `*.gcov` files |

### Hyperparameters
Here are some important hyperparameters. You may see all the hyperparameters by passing `--help` option to SymTuner.
| Option | Description |
|:------:|:------------|
| `--budget` | Total time budget |
| `--search-space` | Path to json file that defines parameter spaces |

If you do not specify search space, SymTuner will use the default search seaces.
You can give your own search space that you are interested in with `--search-space` option.
`--generate-search-space-json` option will generate an example json that defines search spaces:
```bash
$ symtuner --generate-search-space-json
# See example-space.json
```

In the json file, there are two entries;
`space` for paramters that SymTuner to tune, and `defaults` for parameters to use directly without tuning.
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
Each tuning space is defined by argument space (first argument, which is an inner list) and maximum repeatability of argument.

#### KLEE based SymTuner
For KLEE based SymTuner, `null` or `"on"` means turning on the parameter, and `"off"` means turning off the parameter.

### KLEE and GCov
SymTuner needs `klee`, `klee-replay`, and `gcov`.
If you cannot find them in your `PATH`, you need to specify the executables to SymTuner.
| Option | Description |
|:------:|:------------|
| `--klee` | Path to KLEE executable |
| `--klee-replay` | Path to KLEE replay executable |
| `--gcov` | Path to GCove executable |

## Artifact
We offer some instructuions to test some benchmarks at [artifact](./artifact).

## Contribution
We are welcome any issues. Please, leave them in the [Issues](https://github.com/skkusal/symtuner/issues) tab.
If you want to make any contribution, SymTuner has [devcontainer](https://code.visualstudio.com/docs/remote/containers) settings with all requirements are pre-installed.

## Citation
You can cite our paper, if you used our work with your own work.
```
@inproceddings{symtuner,
    author={Cha, Sooyoung and Lee, Myungho and Lee, Seokhyun and Oh, Hakjoo},
    booktitle={2022 IEEE/ACM 43rd International Conference on Software Engineering (ICSE)}, 
    title={SymTuner: Maximizing the Power of Symbolic Execution by Adaptively Tuning External Parameters},
    year={2022}
}
```
