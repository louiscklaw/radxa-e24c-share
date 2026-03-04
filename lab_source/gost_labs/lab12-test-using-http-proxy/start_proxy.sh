#!/usr/bin/env sh

set -ex

# python ./proxy.py
# pipx install pysocks5server
# python -m socks5server --port 1080 --no-auth
# python -m pysocks5server --host 0.0.0.0 --port 1080 --no-auth

microsocks -p 1080 -u user -P pass
