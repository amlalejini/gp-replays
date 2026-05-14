#! /bin/bash

# Allow user to prepare mock (local) jobs with -m and to enable verbose mode
# For debugging purposes, -g turns off the git file and -l skips loading modules (because both are slowt
IS_MOCK=0
IS_VERBOSE=0
LOAD_MODULES=1
SAVE_GIT=1
while getopts "mvgl" OPT; do
  case $OPT in
    m)
      IS_MOCK=1 ;;
    v)
      IS_VERBOSE=1 ;;
    g)
      SAVE_GIT=0 ;;
    l)
      LOAD_MODULES=0 ;;
    \?)
      #echo "Invalid option: -$OPTARG" >&2
      echo "Please fix/remove invalid option"
      exit 1
      ;;
  esac
done

