#!/bin/bash
set -eu

TGZ_FILE=/workspace.tgz
TGZ_FILE_EXTRACTED=/workspace/.workspace.extracted

if [ -r "$TGZ_FILE" ]; then
    if [ -r "$TGZ_FILE_EXTRACTED" ]; then
        echo "$TGZ_FILE as already been untar..."
    else
        echo "Extracting preserved workspace files $TGZ_FILE..."
        tar -xzf $TGZ_FILE -C/
        touch $TGZ_FILE_EXTRACTED
    fi
else
    echo "No $TGZ_FILE to untar..."
fi

echo "Workspace extraction ended with success"