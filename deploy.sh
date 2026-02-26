#!/usr/bin/env bash

set -ex

npm run build

USE_SSH=true npm run deploy

echo "done"

exit 0
