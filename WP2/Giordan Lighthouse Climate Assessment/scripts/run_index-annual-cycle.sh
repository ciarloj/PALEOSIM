#!/bin/bash
{
set -eo pipefail

export frq=$f

vars="windyd summerd tropicn"

for v in $vars; do
  export var=$v
  ncl -Q index-annual-cycle.ncl | grep -v warning
done

}
