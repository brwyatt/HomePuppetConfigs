#!/bin/bash

dir=$(dirname $0)

sudo puppet apply --modulepath="${dir}/puppet/modules" "${dir}/puppet/manifests/default.pp"
