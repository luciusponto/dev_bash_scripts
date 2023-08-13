#!/bin/bash

status () {
	git status
}

log () {
	git log
}

add_all () {
	git add . && echo "" && git status
}

add_all_and_commit () {
	git add . && echo "" && commit &&	echo "" && git status
}

add_commit_push () {
	git add . && echo "" && commit && echo "" && push && echo "" && git status
}

reset_hard () {
	git reset --hard && echo "" && git clean -df
}

push () {
	git push -u origin main
}

pull () {
	git pull origin main
}

get_commit_message () {
	read -p "Type commit message (no quotes): " message
	if [ "$message" == "" ]; then
		echo "No commit message supplied. Aborting."
		return 1
	fi
}

commit () {
	get_commit_message && git commit -m "$message" && echo "" && git log -1
}

display_post_amend_message () {
	echo -e "\nAmmened last commit message in local repo.\nIf the changes were already pushed to the remote repository, run:"
	echo "git push --force [repository-name] [branch-name]"
}

commit_ammend () {
	get_commit_message && git commit --amend -m "$message" && display_post_amend_message
}

list_options () {
	echo -e "\nGit helper. Available commands:\n"
	echo "  s) status"
	echo "  l) log"
	echo "  aa) add ."
	echo "  ac) add . && commit"
	echo "  acp) add . && commit && push"
	echo "  c) commit"
	echo "  am) commit --amend (amend last commit message)"
	echo "  rhc) reset --hard && clean -df (reset hard and delete untracked files)"
	echo "  push) push -u origin main" 
	echo "  pull) pull origin main"
	echo ""
}

quit () {
	do_quit="true"
}

do_quit=false
message=""

while [ "$do_quit" != "true" ]; do
	read -p "Command (s/l/aa/ac/acp/c/am/rhc/push/pull), help(h) or quit(q): " option
	echo ""
	case $option in
	  s) status; quit;;
	  l) log; quit;;
	  aa) add_all; quit;;
	  ac) add_all_and_commit; quit;;
	  acp) add_commit_push; quit;;
	  c) commit; quit;;
	  am) commit_ammend; quit;;
	  rhc) reset_hard; quit;;
	  push) push; quit;;
	  pull) pull; quit;;
	  h) list_options;;
	  q) quit;;
	  *) echo "Invalid option"; list_options; quit;;
	esac
done
