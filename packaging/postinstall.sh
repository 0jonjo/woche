#!/bin/sh
set -e

# Runs as root: configuration is per user, so only point the way
if [ "$1" = "configure" ] && [ -z "$2" ]; then
    echo "woche is installed. Run 'woche init' to choose your language and directory."
fi
