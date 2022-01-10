#! /usr/bin/env bash

BASE_DIRECTORY=$(pwd)
# LOG_LEVEL: DEBUG (0) < INFO (1) < WARN (2) < FAIL (3+)
LOG_LEVEL=${LOG_LEVEL:-"INFO"}
# To disable, set COLORED_PROMPT as OFF, otherwise enabled
COLORED_PROMPT=${COLORED_PROMPT:-"ON"}
GREEN=
WHITE=
YELLOW=
RED=
RESET=
if ! [ $COLORED_PROMPT = "OFF" ]; then
    GREEN="\033[0;32m"
    WHITE="\033[0;37m"
    YELLOW="\033[1;33m"
    RED="\033[0;31m"
    RESET="\033[0m"
fi

NOBJ=$NOBJ

function sudoIf () {
    if [ "$(id -u)" -ne 0 ] ; then
        sudo $@
    else
        $@
    fi
}

function get_log_level_integer () {
    local level_string
    local level
    level_string=$(echo $1 | tr 'a-z', 'A-Z')
    case $level_string in
    "DEBUG") level=0;;
    "INFO") level=1;;
    "WARN") level=2;;
    "FAIL") level=3;;
    esac
    return $level
}

function log () {
    local log_level
    local level_string
    local message_level
    
    get_log_level_integer $LOG_LEVEL
    log_level=$?

    level_string=$(echo $1 | tr 'a-z', 'A-Z')
    get_log_level_integer $level_string
    message_level=$?

    if [ $message_level -ge $log_level ]; then
        case $message_level in
        "0") echo -e $GREEN[DEBUG]$RESET $2;;
        "1") echo -e $WHITE[INFO]$RESET $2;;
        "2") echo -e $YELLOW[WARN]$RESET $2;;
        "3") echo -e $RED[FAIL]$RESET $2;;
        esac
    fi
}

function install_dependencies () {
    sudoIf apt-get update
    sudoIf apt-get install automake
}

function download_source_tgz () {
    if [ -d "$1" ]; then
        log INFO "Already downloaded: $1"
        return 0
    fi
    curl -sk $2 | tar xz
    if ! [ -d "$1" ]; then
        log FAIL "Download failed: $1"
        return 1
    fi
}

function download_source_txz () {
    if [ -d "$1" ]; then
        log INFO "Already downloaded: $1"
        return 0
    fi
    curl -sk $2 | tar xJ
    if ! [ -d "$1" ]; then
        log FAIL "Download failed: $1"
        return 1
    fi
}

function build_gcov_obj () {
    if [ -f "$1/$2" ]; then 
        log INFO "Gcov object already built: $1/$2"
        return 0
    fi
    mkdir -p $1
    cd $1
    ../configure --disable-nls CFLAGS="-g -fprofile-arcs -ftest-coverage" > /dev/null && make > /dev/null
    cd ..
    if ! [ -f "$1/$2" ]; then 
        return 1
    fi
}

function build_multiple_gcov_obj () {
    if [ "$NOBJ" = "" ] ; then
        build_gcov_obj $1 $2
        return $?
    fi

    for i in $(seq 1 $NOBJ) ; do
        build_gcov_obj $1$i $2
    done
}

function build_llvm_obj () {
    local base_dir
    base_dir=$(pwd)
    if [ -f "$1/$2" ]; then 
        log INFO "LLVM object already built: $1/$2"
        return 0
    fi
    mkdir -p $1
    cd $1
    LLVM_COMPILER=clang CC=wllvm ../configure --disable-nls CFLAGS="-g -O1 -Xclang -disable-llvm-passes -D__NO_STRING_INLINES  -D_FORTIFY_SOURCE=0 -U__OPTIMIZE__" > /dev/null && \
    LLVM_COMPILER=clang make > /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    if ! [ -z $3 ]; then 
        cd $3
    fi
    find . -executable -type f | xargs -I '{}' extract-bc '{}'
    cd $base_dir
    if ! [ -f "$1/$2" ]; then
        return 1
    fi
}

function build_multiple_llvm_obj () {
    local retcode
    build_llvm_obj $1 $2 $3
    retcode=$?
    if [ "$NOBJ" = "" ] ; then
        return $retcode
    fi

    for i in $(seq 1 $NOBJ) ; do
        if [ -f "$1$i/$2" ] ; then
            log INFO "LLVM object already exists: $1$i/$2"
        else
            cp -r $1 $1$i
            log INFO "Create LLVM objct: $1$i/$2"
        fi
    done
}

function build_combine-0.4.0 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: combine-0.4.0"
    download_source_tgz combine-0.4.0 https://ftp.gnu.org/gnu/combine/combine-0.4.0.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build combine-0.4.0"
        return 1
    fi

    cd $BASE_DIRECTORY/combine-0.4.0
    log INFO "Build gcov object: combine-0.4.0"
    build_multiple_gcov_obj obj-gcov src/combine
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: combine-0.4.0"
    fi

    cd $BASE_DIRECTORY/combine-0.4.0
    log INFO "Build LLVM object: combine-0.4.0"
    build_multiple_llvm_obj obj-llvm src/combine.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: combine-0.4.0"
    fi
    log INFO "Build process finished: combine-0.4.0"
}

function build_diff-3.7 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: diffutils-3.7"
    download_source_txz diffutils-3.7 https://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build diffutils-3.7"
        return 1
    fi

    cd $BASE_DIRECTORY/diffutils-3.7
    log INFO "Build gcov object: diff-3.7"
    build_multiple_gcov_obj obj-gcov src/diff
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: diff-3.7"
    fi

    cd $BASE_DIRECTORY/diffutils-3.7
    log INFO "Build LLVM object: diff-3.7"
    build_multiple_llvm_obj obj-llvm src/diff.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: diff-3.7"
    fi
    log INFO "Build process finished: diff-3.7"
}

function build_du-8.32 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: coreutils-8.32"
    download_source_tgz coreutils-8.32 https://ftp.gnu.org/gnu/coreutils/coreutils-8.32.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build coreutils-8.32"
        return 1
    fi

    cd $BASE_DIRECTORY/coreutils-8.32
    log INFO "Build gcov object: du-8.32"
    build_multiple_gcov_obj obj-gcov src/du
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: du-8.32"
    fi

    cd $BASE_DIRECTORY/coreutils-8.32
    log INFO "Build LLVM object: du-8.32"
    build_multiple_llvm_obj obj-llvm src/du.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: du-8.32"
    fi
    log INFO "Build process finished: du-8.32"
}

function build_enscript-1.6.6 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: enscript-1.6.6"
    download_source_tgz enscript-1.6.6 https://ftp.gnu.org/gnu/enscript/enscript-1.6.6.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build enscript-1.6.6"
        return 1
    fi

    cd $BASE_DIRECTORY/enscript-1.6.6
    log INFO "Build gcov object: enscript-1.6.6"
    build_multiple_gcov_obj obj-gcov src/enscript
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: enscript-1.6.6"
    fi

    cd $BASE_DIRECTORY/enscript-1.6.6
    log INFO "Build LLVM object: enscript-1.6.6"
    build_multiple_llvm_obj obj-llvm src/enscript.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: enscript-1.6.6"
    fi
    log INFO "Build process finished: enscript-1.6.6"
}

function build_gawk-5.1.0 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: gawk-5.1.0"
    download_source_tgz gawk-5.1.0 https://ftp.gnu.org/gnu/gawk/gawk-5.1.0.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build gawk-5.1.0"
        return 1
    fi

    cd $BASE_DIRECTORY/gawk-5.1.0
    log INFO "Build gcov object: gawk-5.1.0"
    build_multiple_gcov_obj obj-gcov gawk
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: gawk-5.1.0"
    fi

    cd $BASE_DIRECTORY/gawk-5.1.0
    log INFO "Build LLVM object: gawk-5.1.0"
    build_multiple_llvm_obj obj-llvm gawk.bc
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: gawk-5.1.0"
    fi
    log INFO "Build process finished: gawk-5.1.0"
}

function build_gcal-4.1 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: gcal-4.1"
    download_source_tgz gcal-4.1 https://ftp.gnu.org/gnu/gcal/gcal-4.1.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build gcal-4.1"
        return 1
    fi

    cd $BASE_DIRECTORY/gcal-4.1
    log INFO "Build gcov object: gcal-4.1"
    build_multiple_gcov_obj obj-gcov src/gcal
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: gcal-4.1"
    fi

    cd $BASE_DIRECTORY/gcal-4.1
    log INFO "Build LLVM object: gcal-4.1"
    build_multiple_llvm_obj obj-llvm src/gcal.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: gcal-4.1"
    fi
    log INFO "Build process finished: gcal-4.1"
}

function build_grep-3.4 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: grep-3.4"
    download_source_txz grep-3.4 https://ftp.gnu.org/gnu/grep/grep-3.4.tar.xz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build grep-3.4"
        return 1
    fi

    cd $BASE_DIRECTORY/grep-3.4
    log INFO "Build gcov object: grep-3.4"
    build_multiple_gcov_obj obj-gcov src/grep
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: grep-3.4"
    fi

    cd $BASE_DIRECTORY/grep-3.4
    log INFO "Build LLVM object: grep-3.4"
    build_multiple_llvm_obj obj-llvm src/grep.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: grep-3.4"
    fi
    log INFO "Build process finished: grep-3.4"
}

function build_ls-8.32 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: coreutils-8.32"
    download_source_tgz coreutils-8.32 https://ftp.gnu.org/gnu/coreutils/coreutils-8.32.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build coreutils-8.32"
        return 1
    fi

    cd $BASE_DIRECTORY/coreutils-8.32
    log INFO "Build gcov object: ls-8.32"
    build_multiple_gcov_obj obj-gcov src/ls
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: ls-8.32"
    fi

    cd $BASE_DIRECTORY/coreutils-8.32
    log INFO "Build LLVM object: ls-8.32"
    build_multiple_llvm_obj obj-llvm src/ls.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: ls-8.32"
    fi
    log INFO "Build process finished: ls-8.32"
}

function build_nano-4.9 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: nano-4.9"
    download_source_tgz nano-4.9 https://ftp.gnu.org/gnu/nano/nano-4.9.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build nano-4.9"
        return 1
    fi

    cd $BASE_DIRECTORY/nano-4.9
    log INFO "Build gcov object: nano-4.9"
    build_multiple_gcov_obj obj-gcov src/nano
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: nano-4.9"
    fi

    cd $BASE_DIRECTORY/nano-4.9
    log INFO "Build LLVM object: nano-4.9"
    build_multiple_llvm_obj obj-llvm src/nano.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: nano-4.9"
    fi
    log INFO "Build process finished: nano-4.9"
}

function build_sed-4.8 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: sed-4.8"
    download_source_tgz sed-4.8 https://ftp.gnu.org/gnu/sed/sed-4.8.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build sed-4.8"
        return 1
    fi

    cd $BASE_DIRECTORY/sed-4.8
    log INFO "Build gcov object: sed-4.8"
    build_multiple_gcov_obj obj-gcov sed/sed
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: sed-4.8"
    fi

    cd $BASE_DIRECTORY/sed-4.8
    log INFO "Build LLVM object: sed-4.8"
    build_multiple_llvm_obj obj-llvm sed/sed.bc sed
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: sed-4.8"
    fi
    log INFO "Build process finished: sed-4.8"
}

function build_trueprint-5.4 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: trueprint-5.4"
    download_source_tgz trueprint-5.4 https://ftp.gnu.org/gnu/trueprint/trueprint-5.4.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build trueprint-5.4"
        return 1
    fi

    cd $BASE_DIRECTORY/trueprint-5.4
    log INFO "Build gcov object: trueprint-5.4"
    build_multiple_gcov_obj obj-gcov src/trueprint
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: trueprint-5.4"
    fi

    cd $BASE_DIRECTORY/trueprint-5.4
    log INFO "Build LLVM object: trueprint-5.4"
    build_multiple_llvm_obj obj-llvm src/trueprint.bc src
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: trueprint-5.4"
    fi
    log INFO "Build process finished: trueprint-5.4"
}

function build_xorriso-1.5.2 () {
    cd $BASE_DIRECTORY
    log INFO "Downloading: xorriso-1.5.2"
    download_source_tgz xorriso-1.5.2 https://ftp.gnu.org/gnu/xorriso/xorriso-1.5.2.tar.gz
    downloaded=$?
    if [ $downloaded -ne 0 ]; then
        log FAIL "Failed to build xorriso-1.5.2"
        return 1
    fi

    cd $BASE_DIRECTORY/xorriso-1.5.2
    log INFO "Build gcov object: xorriso-1.5.2"
    build_multiple_gcov_obj obj-gcov xorriso/xorriso
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build gcov object: xorriso-1.5.2"
    fi

    cd $BASE_DIRECTORY/xorriso-1.5.2
    log INFO "Build LLVM object: xorriso-1.5.2"
    build_multiple_llvm_obj obj-llvm xorriso/xorriso.bc xorriso
    if [ $? -ne 0 ] ; then
        log FAIL "Failed to build LLVM object: xorriso-1.5.2"
    fi
    log INFO "Build process finished: xorriso-1.5.2"
}

function help () {
    cat <<-EOF
Usage: $0 [-h|--help] [-l|--list] [--n-objs INT]
        <benchmark> [<benchmark> ...]
Optional arguments:
    -h, --help      Print this list
    -l, --list      List benchmarks
        --n-objs INT
                    Build multiple objects
        
Positional arguments:
    <benchmark>     The name of benchmark, see the supported list
                    with --list option
EOF
}

function list () {
    cat <<-EOF
Benchmark lists
    combine-0.4.0
    diff-3.7        diffutils-3.7
    du-8.32         coreutils-8.32
    enscript-1.6.6
    gawk-5.1.0
    gcal-4.1
    grep-3.4
    ls-8.32         coreutils-8.32
    nano-4.9
    sed-4.8
    trueprint-5.4
    xorriso-1.5.2
    all             download and build all
EOF
}


function build () {
    case $1 in
    "combine-0.4.0") build_combine-0.4.0;;
    "diff-3.7") build_diff-3.7;;
    "du-8.32") build_du-8.32;;
    "enscript-1.6.6") build_enscript-1.6.6;;
    "gawk-5.1.0") build_gawk-5.1.0;;
    "gcal-4.1") build_gcal-4.1;;
    "grep-3.4") build_grep-3.4;;
    "ls-8.32") build_ls-8.32;;
    "nano-4.9") build_nano-4.9;;
    "sed-4.8") build_sed-4.8;;
    "trueprint-5.4") build_trueprint-5.4;;
    "xorriso-1.5.2") build_xorriso-1.5.2;;
    *) log WARN "Unknown benchmark: $1";;
    esac
}

if [ -z "$1" ] ; then
    help
    exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
    help
    exit 0
fi

if [ "$1" = "-l" ] || [ "$1" = "--list" ] ; then
    list
    exit 0
fi

if [ "$1" = "--n-objs" ] ; then
    NOBJ=$2
    shift
    shift
fi

if [ "$1" = "all" ] ; then
    benchmarks="combine-0.4.0 diff-3.7 du-8.32 enscript-1.6.6 gawk-5.1.0 gcal-4.1 grep-3.4 ls-8.32 nano-4.9 sed-4.8 trueprint-5.4 xorriso-1.5.2"
else
    benchmarks=$@
fi

for benchmark in $benchmarks; do
    build $benchmark
done
