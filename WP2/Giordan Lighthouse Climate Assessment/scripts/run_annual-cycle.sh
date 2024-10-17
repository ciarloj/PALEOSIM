#!/bin/bash
{
set -eo pipefail

export frq=$f

vars="winddir windspeed rhus tas dtas ps"

for v in $vars; do
  export var=$v
  ncl -Q annual-cycle.ncl | grep -v warning
done

}
