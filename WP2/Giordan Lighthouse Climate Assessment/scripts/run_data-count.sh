#!/bin/bash
{
set -eo pipefail

vars="winddir windspeed rhus tas dtas ps"
vars=ps

for v in $vars; do
  export var=$v
  echo $v ..
  ncl -Q color-table-data-count.ncl | grep -v warning 
done

}
