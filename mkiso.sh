#!/bin/bash

BASEDIR=$(dirname "$0")

genisoimage -U -R -J -joliet-long -iso-level 4 -o "${BASEDIR}/../HomePuppetConfigs.iso" "${BASEDIR}/"
