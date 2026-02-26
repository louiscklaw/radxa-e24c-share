#!/usr/bin/env bash

set -ex

git add .

npm run build

git commit -m'update publish,'

echo "done"
exit 0