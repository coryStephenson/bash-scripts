#! usr/bin/env bash

set -euo pipefail
set -o errtrace

help()
{
    man pcal
    exit 2
}


while getopts ef:o:lpPjJmMg:O:G:bs::F:AEX:Y:x:y:t::d::n::L:C:R:N:D:U:B:\#:SkKwIcHqz:huva:r::T::W:: flag
do
  case "${flag}" in
    -c | --city1 )
      city1="$2"
      shift 2
      ;;
    -d | --city2 )
      city2="$2"
      shift 2
      ;;
    -h | --help)
      help
      ;;
    --)
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
done

if [ "$city1" ] && [ -z "$city2" ]
then
    curl -s "https://wttr.in/${city1}"
elif [ -z "$city1" ] && [ "$city2" ]
then
    curl -s "https://wttr.in/${city2}"
elif [ "$city1" ] && [ "$city2" ]
then
    diff -Naur <(curl -s "https://wttr.in/${city1}" ) <(curl -s "https://wttr.in/${city2}" )
else
    curl -s https://wttr.in
fi

