#!/usr/bin/env bash

# Vivado batch email notification configuration example.
# Copy this file to scripts/vivado2018_notify_env.local.sh and edit it.
# Do not commit real private email/password/secrets.

export BUILD_NOTIFY_ENABLE=1
export BUILD_NOTIFY_EMAIL="gaoray1999@gmail.com"
export BUILD_NOTIFY_SUBJECT_PREFIX="[Vivado dspboard] "
