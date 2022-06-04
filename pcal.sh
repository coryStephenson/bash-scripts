#! usr/bin/env bash

set -euo pipefail
set -o errtrace

help()
{
    man pcal
    exit 2
}

SHORT=e,f:,o:,l,p,P,j,J,m,M,g:,O:,G:,b,s:,F:,A,E,X:,Y:,x:,y:,t:,d:,n:,L:,C:,R:,N:
LONG=city1:,city2:,help
OPTS=$(getopt -a -n weather --options $SHORT -- "$@")

VALID_ARGUMENTS=$# # Returns the count of arguments that are in short or long options

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  help
fi

eval set -- "$OPTS"

while :
do
  case "$1" in
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

