#!/bin/bash
# exit immediately if a command fails
set -e
# error on unset variables
set -u

cd ../bbolt-benchmark
# Get advice type from the command line or use "no" as default
advice_type=${1:-"no"}

# Define an array of operation modes
declare -a modes=("seq"  "rnd" )

# Function to extract values from a diff file
extract_values() {
  local mode=$1
  local file="diff_${advice_type}-madvise-${mode}.txt"
  
  # Check if file exists
  if [ ! -f "$file" ]; then
    # If file does not exist, output default values to maintain output consistency
    echo -e "0.0\n0.0"
    return
  fi

  # Extracting the non-base (second column) values for Write and Read, only output numbers
  local write=$(awk '/Write/{print $2}' "$file" | tr -d 'µ')
  local read=$(awk '/Read/{print $2}' "$file" | tr -d 'n')
  # Output the extracted numerical values
  echo -e "$write"
  echo -e "$read"
}

# Loop through each mode and extract values
for mode in "${modes[@]}"; do
  extract_values "$mode"
done
