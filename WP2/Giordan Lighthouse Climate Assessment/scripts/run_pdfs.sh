#!/bin/bash
{
set -eo pipefail

frqs="hr daymean daymax daymin"
for f in $frqs; do
  export frq=$f

  vars="winddir windspeed rhus tas dtas ps"
  [[ $f = daymax ]] && vars="tas ps windspeed"
  [[ $f = daymin ]] && vars="tas ps windspeed"

  for v in $vars; do
    export var=$v
    ncl -Q pdfs.ncl | grep -v warning
  done
done

}
