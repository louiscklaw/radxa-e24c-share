#!/usr/bin/env bash

set -ex

git add .

npm run build

git commit -m'update publish,'

git push

echo "done"
exit 0