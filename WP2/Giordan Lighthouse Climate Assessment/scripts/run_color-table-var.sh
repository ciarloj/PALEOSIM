#!/bin/bash
{
set -eo pipefail

vars="tas summerd tropicn windyd"
vars="rhus"

for v in $vars; do
  export var=$v
  echo $v ..
  ncl -Q color-table-var.ncl | grep -v warning 
done

}
