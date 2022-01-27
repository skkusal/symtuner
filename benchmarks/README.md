# Benchmarks
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

## How to Build Benchmarks
The provided script (`make-paper-benchmark.sh`) will help you download and build the benchmarks.
For example, if you want to build `combine-0.4.0` and `gcal-4.1`, just use the following command:
```bash
$ ./make-paper-benchmark.sh combine-0.4.0 gcal-4.1
```
The script offers `all` options to build all 12 benchmarks.
```bash
$ ./make-paper-benchmark.sh all
```

If you need further infomation use `--help` option:
```bash
$ ./make-paper-benchmark.sh --help
```

## How to run SymTuner for Testing Benchmarks
This section assume that SymTuner is installed.
If you have not installed yet, please follow the instructions at [here](https://github.com/skkusal/symtuner).
After installation, you can run SymTuner to test gcal-4.1 with a default parameter space used in our paper as the following commands:
```bash
$ ./make-paper-benchmarks gcal-4.1  # build gcal-4.1
$ symtuner gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
```
In this way, SymTuner is able to test all benchmarks easily, except for two benchmarks mentioned in [Notes](#Notes).

### Notes
There are some benchmarks that needs more options.

#### Runing SymTuner with the Option `optimize' Turned off
Some benchmarks immediately terminated when the `-optimize` option turned on.
Therefore, `-optimize` option needs to be removed to test the following benchmarks:
* gawk-5.1.0
* trueprint-5.4

`no-optimize.json` is our default parameter space setting with `-optimize` option removed.
You can directly test those benchmarks with the modified search space:
```bash
$ symtuner --search-space no-optimize.json trueprint-5.4/obj-llvm/src/trueprint.bc trueprint-5.4/obj-gcov/src/trueprint
```

#### Running SymTuner with GCov Depth Adjustment
All executables in benchmarks provided, except for gawk-5.1.0, located in the 1 level depth of folder from the root.
However, gawk-5.1.0 executable located in the root directory, so `--gcov-depth` should be set as 0:
```bash
$ symtuner --search-space no-optimize.json --gcov-depth 0 gawk-5.1.0/obj-llvm/gawk.bc gawk-5.1.0/obj-gcov/gawk
```

### How to Test without Parameter Tuning
To test without tuning, you can give SymTuner an empty parameter space (which is defined with `"space"` key in a json file).
`no-tuning.json` gives some default parameters that can be used to test benchmarks without tuning:
```bash
$ cat no-tuning.json
{
    "space": {},
    "defaults": {
        "-output-module": "false",
...
# run symtuner without parameter-tuning
$ symtuner --search-space no-tuning.json --output-dir default-out gcal-4.1/obj-llvm/src/gcal.bc gcal-4.1/obj-gcov/src/gcal
```
