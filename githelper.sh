#!/bin/bash

status () {
	git status
}

log () {
	git log
}

add_all () {
	git add . && git status
}

add_all_and_commit () {
	git add . && commit &&	git status
}

add_commit_push () {
	git add . && commit && push &&	git status
}

reset_hard () {
	git reset --hard && git clean -df
}

push () {
	git push -u origin main
}

pull () {
	git pull origin main
}

commit () {
	read -p "Type commit message: " message
	if [ "$message" == "" ]; then
		echo "No commit message supplied. Aborting."
		return 1
	fi
	git commit -m "$message"
}

list_options () {
	echo "  s) status"
	echo "  l) log"
	echo "  aa) add ."
	echo "  ac) add . && commit"
	echo "  acp) add . && commit && push"
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
	read -p "Choose git command (s/l/aa/ac/acp/c/rhc/push/pull), list options(o) or quit(q): " option
	case $option in
	  s) status; quit;;
	  l) log; quit;;
	  aa) add_all; quit;;
	  ac) add_all_and_commit; quit;;
	  acp) add_commit_push; quit;;
	  c) commit; quit;;
	  rhc) reset_hard; quit;;
	  push) push; quit;;
	  pull) pull; quit;;
	  o) list_options;;
	  q) quit;;
	  *) echo "invalid option";;
	esac
done
