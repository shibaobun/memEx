#!/usr/bin/env sh
set -ou pipefail

cat /dev/urandom | base64 | head -c 64
