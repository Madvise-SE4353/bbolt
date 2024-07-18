#!/bin/bash
# exit immediately when a command fails
set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail
# error on unset variables
set -u

# Mapping for advice to system calls
declare -A advice_map=(
    [no]="MADV_NORMAL"
    [seq]="MADV_SEQUENTIAL"
    [rnd]="MADV_RANDOM"
    [huge]="MADV_HUGEPAGE"
    [noneed]="MADV_DONTNEED"
    [willneed]="MADV_WILLNEED"
)

# Get advice type from the command line or default to "all" to run for all types
BENCH_ADVICE=${1:-"all"}

REF_CURRENT="$(git rev-parse --abbrev-ref HEAD)"
RESULT_CURRENT="$(mktemp)-${REF_CURRENT}"
BENCH_COUNT=${BENCH_COUNT:-5}
BENCHSTAT_CONFIDENCE_LEVEL=${BENCHSTAT_CONFIDENCE_LEVEL:-0.9}
BENCHSTAT_FORMAT=${BENCHSTAT_FORMAT:-"text"}

# Modify and rebuild bbolt for the specified advice
function modify_and_rebuild() {
    local advice=$1
    echo "Modifying for advice: $advice (${advice_map[$advice]})"
    cd ..
    sed -i "s/MADV_[A-Z_]*\b/${advice_map[$advice]}/" "bolt_unix.go"
    echo "Rebuilding bbolt-benchmark after advice change"
    make build
    cd bbolt-benchmark
}

# Clear system caches to ensure clean benchmark conditions
function clear_caches() {
    echo "Clearing system caches to ensure a clean benchmark environment..."
    sudo sync && sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
}

# Perform benchmarks and comparisons
function bench_and_compare() {
    local advice=$1
    local mode=$2
    local output_file="bench-${advice}-madvise-${mode%% *}"
    local base_file="bench-no-${advice}-madvise-${mode%% *}"

    echo "Benchmarking for mode: ${mode} with advice: ${advice}"
    for _ in $(seq "$BENCH_COUNT"); do
        clear_caches
        local parameters="-count 1000000 -batch-size 1000 -write-mode ${mode%% *} -read-mode ${mode##* }"
        ../bin/bbolt bench -gobench-output -profile-mode n ${parameters} >> "${output_file}"
    done

    if [ ! -f "${base_file}" ]; then
        echo "Base file ${base_file} not found. Using output file as base for comparison."
        base_file="${output_file}"
    fi
    local output_diff="diff_${advice}-madvise-${mode%% *}.txt"
    benchstat -confidence="${BENCHSTAT_CONFIDENCE_LEVEL}" "${base_file}" "${output_file}" > "${output_diff}"
    echo "Results written to ${output_diff}"
}

# Main function to handle all modes and advice types
function main() {
    cd ../bbolt-benchmark
    # declare -a modes=("seq seq" "seq-nest seq" "rnd rnd" "rnd-nest rnd")
    declare -a modes=("seq seq"  "rnd rnd" )

    if [[ "$BENCH_ADVICE" == "all" ]]; then
        for advice in "${!advice_map[@]}"; do
            modify_and_rebuild "$advice"
            for mode in "${modes[@]}"; do
                bench_and_compare "$advice" "$mode"
            done
        done
    else
        modify_and_rebuild "$BENCH_ADVICE"
        for mode in "${modes[@]}"; do
            bench_and_compare "$BENCH_ADVICE" "$mode"
        done
    fi
    echo "Benchmarking and comparison completed."
}

main
