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

add_all_and_commit () {
	git add .
	commit
	git status
	quit
}

reset_hard () {
	git reset --hard && git clean -df
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
	echo "  ac) add . && commit"
	echo "  c) commit"
	echo "  rhc) reset --hard && clean -df (reset hard and delete untracked files)"
	echo "  push) push -u origin main" 
	echo "  pull) pull origin main"
}

quit () {
	do_quit="true"
}

do_quit=false

while [ "$do_quit" != "true" ]; do
	read -p "Choose git command (s/l/aa/ac/c/rhc/push/pull), list options(o) or quit(q): " option
	case $option in
	  s) status;;
	  l) log;;
	  aa) add_all;;
	  ac) add_all_and_commit;;
	  c) commit;;
	  rhc) reset_hard;;
	  push) push;;
	  pull) pull;;
	  o) list_options;;
	  q) quit;;
	  *) echo "invalid option";;
	esac
done
