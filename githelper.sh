#!/bin/bash

status () {
	git status
	quit
}

log () {
	git log
	quit
}

add_all () {
	git add .
	git status
	quit
}

reset_hard () {
	git reset --hard
	quit
}

push () {
	git push -u origin main
	quit
}

pull () {
	git pull origin main
	quit
}

commit () {
	read -p "Type commit message: " message
	git commit -m "$message"
	quit
}

list_options () {
	echo "  s) status"
	echo "  l) log"
	echo "  aa) add ."
	echo "  c) commit"
	echo "  rh) reset --hard"
	echo "  push) push -u origin main" 
	echo "  pull) pull origin main"
}

quit () {
	do_quit="true"
}

do_quit=false

while [ "$do_quit" != "true" ]; do
	echo "choose git command (s/l/aa/c/rh/push/pull), list options(o) or quit(q):\n"

	read n
	case $n in
	  s) status;;
	  l) log;;
	  aa) add_all;;
	  c) commit;;
	  rh) reset_hard;;
	  push) push;;
	  pull) pull;;
	  o) list_options;;
	  q) quit;;
	  *) echo "invalid option";;
	esac
done
