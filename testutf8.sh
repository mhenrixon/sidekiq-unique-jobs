#!/bin/bash

# Loop through all files in the repository
find ./lib -type f | while read file; do
  # if ! rubocop $file > /dev/null 2>&1; then
  #   echo "Invalid UTF-8 in file: $file"
  # fi

  # Attempt to convert the file encoding from UTF-8 to UTF-8, checking for invalid sequences
  if ! iconv -f UTF-8 -t UTF-8 "$file" > /dev/null 2>&1; then
    # If iconv exits with a non-zero status, the file contains invalid UTF-8 sequences
    echo "Invalid UTF-8 in file: $file"
  fi
done
