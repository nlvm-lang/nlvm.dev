#!/usr/bin/env bash
#
# https://nlvm.dev/install.sh — thin proxy to the canonical installer,
# which lives in the nlvm-lang/nlvm repository.

set -e
exec bash -c "$(curl -fsSL https://raw.githubusercontent.com/nlvm-lang/nlvm/main/install.sh)"
