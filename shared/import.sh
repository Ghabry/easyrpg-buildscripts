#!/bin/bash

_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $_SCRIPT_DIR/common.sh
source $_SCRIPT_DIR/packages.sh

# Allow overwriting by a custom package file
if [ -f "packages.sh" ]; then
	source packages.sh
fi
