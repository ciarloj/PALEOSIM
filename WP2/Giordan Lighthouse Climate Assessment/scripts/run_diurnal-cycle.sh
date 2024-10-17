#!/bin/bash
{
set -eo pipefail

vars="winddir windspeed rhus tas dtas ps"

for v in $vars; do
  export var=$v
  ncl -Q diurnal-cycle.ncl | grep -v warning
done

}
