#!/bin/bash
executable=$(which $1)
if [ "$executable" == "" ] || [ ! -f "$executable" ]; then
    expression="alias $1"
    sub_home=$(echo "s/~/${HOME}/g")
    executable=$(grep -e "alias $1=" ~/.bash_aliases | sed -e "s/^[^=]*=//g" | sed -e "s/'//g")
fi
if [ "$executable" == "" ] || [ ! -f "$executable" ]; then
    echo "Could not find executable with name: $1"
    exit 1
fi
shift
${executable} $@ &>/dev/null & disown;

