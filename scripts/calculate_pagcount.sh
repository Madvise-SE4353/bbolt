#!/bin/bash

# Check if a file path is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <file_path>"
    exit 1
fi

file_path=$1

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "Error: File not found at '$file_path'"
    exit 1
fi

# Extract PageCount values and calculate their mean
total=0
count=0

while IFS= read -r line; do
    if [[ $line =~ PageCount:\ ([0-9]+) ]]; then
        total=$((total + BASH_REMATCH[1]))
        count=$((count + 1))
    fi
done < "$file_path"

if [ $count -gt 0 ]; then
    mean=$(echo "scale=2; $total / $count" | bc)
    echo "Mean PageCount: $mean"
else
    echo "No PageCount values found in the file."
fi
