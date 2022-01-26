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

## How to Test Benchmarks
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

#### How to Test One Program In Parallel
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
Some benchmarks immediately terminated when the `-optimize` option turned on.
Therefore, `-optimize` option needs to be removed to test the following benchmarks:
* gawk-5.1.0
* trueprint-5.4

`space-without-optimize.json` is a default parameter space setting with `-optimize` option removed.
You can directly use the space for testing those benchmarks:
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

### How to Testi without Parameter Tuning
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
