#!/bin/bash

dir=$(dirname $0)

sudo puppet apply --no-stringify_facts --modulepath="${dir}/puppet/modules" "${dir}/puppet/manifests/default.pp"
