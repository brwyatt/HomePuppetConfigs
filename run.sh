#!/bin/bash

dir=$(dirname $0)

puppet apply "$@" --modulepath="${dir}/puppet/modules" "${dir}/puppet/manifests/default.pp"
