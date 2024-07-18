#!/bin/bash

# Calculate the number of key-value pairs and the size of each value
numPairs=16000  # Number of key-value pairs
valueSize=1024  # Size of each value in bytes (1KB)

# Create a large value
value=$(printf 'a%.0s' $(seq 1 $valueSize))

# Insert key-value pairs
for i in $(seq 1 $numPairs)
do
  key="key$i"
  etcdctl put $key $value
  echo "Inserted $key"
done

echo "Database population complete."
