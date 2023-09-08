#!/bin/bash

status () {
	git status && echo "" 
}

log () {
	git log --oneline && echo "" 
}

add_all () {
	git add . && echo "" && git status && echo "" 
}

add_all_and_commit () {
	git add . && echo "" && commit && echo "" && git status && echo "" 
}

add_all_commit_push () {
	git add . && echo "" && commit && echo "" && push && echo "" && git status && echo "" 
}

reset_hard () {
	git reset --hard && echo "" && git clean -df && echo "" 
}

push () {
	remotes=$(git remote | tr "\n" "/" | sed -e "s/\/$//")
	if [ $remotes == "" ]; then
		echo "No remotes configured. Aborting push command."
		return 1
	fi
	branches=$(git branch | sed -e "s/^[* ] //" | tr "\n" "/" | sed -e "s/\/$//")
	read -p "remote name ($remotes): " remote && read -p "branch to push ($branches): " branch
	git push -u $remote $branch && echo "" 
}

pull () {
	git pull origin main && echo "" 
}

get_commit_message () {
	read -p "Type commit message (no quotes): " message
	if [ "$message" == "" ]; then
		echo "No commit message supplied. Aborting."
		return 1
	fi
}

commit () {
	get_commit_message && git commit -m "$message" && echo "" && git log -1 && echo "" 
}

display_post_amend_message () {
	echo -e "\nAmmened last commit message in local repo.\nIf the changes were already pushed to the remote repository, run:"
	echo -e "git push --force [repository-name] [branch-name]\n"
}

commit_ammend () {
	get_commit_message && git commit --amend -m "$message" && display_post_amend_message
}

print_args () {
	# echo "----------------------------------------------------------------------"
	echo "-- $1:"
	echo "$2"
	echo ""
}

print_cheat_sheet () {
	echo -e "In the below, [remote] is the remote repo name, like \"origin\"; [branch] is a branch name, like \"main\"\n"
	print_args "Create local branch" "git branch [branch]"
	print_args "Push local branch to remote, create if needed" "git push -u [remote] [branch]"
	print_args "Pull remote branch to local" "git pull [remote] [branch]"
	print_args "Switch to another branch" "git switch [branch]"
	print_args "Merge into current branch, squashing other branch commits" " git merge --squash [other_branch]"
	print_args "Delete local branch" "git branch -d [branch]"
	print_args "Delete remote branch" "git push [remote] --delete [branch]"
	print_args "Push uncommited changes into stash stack, not including untracked files" "git stash push -m \"[message]\""
	print_args "Push uncommited changes into stash stack, including untracked files" "git stash push --include-untracked -m \"[message]\""
	print_args "List stashes" "git stash list"
	print_args "Show contents of stash as list of files; <revision> from \"git stash list\"" "git stash show stash@{<revision>} --include-untracked"
	print_args "Show contents of stash as patch; <revision> from \"git stash list\"" "git stash show stash@{<revision>} -p --include-untracked"
	print_args "Apply contents of stash to working copy, keeping stash, <revision> from \"git stash list\"" "git stash apply stash@{<revision>}"
	print_args "Apply contents of stash to working copy, then delete stash, <revision> from \"git stash list\"" "git stash pop stash@{<revision>}"
	print_args "Delete stash, <revision> from \"git stash list\"" "git stash drop stash@{<revision>}"
	# echo -e "Push branch to remote, create if needed:\npush -u origin main\n\n" 
	# echo "  pull) pull origin main"
}

diff () {
	files=$(git status | grep -Ee "^.*(modified:|added:|removed:).*$" | sed -e "s/.* //")
	filecount=$(echo -e "$files" | wc -l)
	[ $filecount -eq 0 ] && echo "No modified files found" && return 3
	i=0
	for file in $files; do
		let i=$i+1
		echo "$i - $file"
	done
	echo ""
	read -p "Desired file number (1 - $filecount): " fnumber
	num_regex="^[0-9]+$"
	if ! [[ $fnumber =~ $num_regex ]] ; then
		echo "Invalid option: $fnumber. Not a number."
		return 1
	fi
	if [ $fnumber -lt 1 ] || [ $fnumber -gt $filecount ]; then
		echo "Not in range: $fnumber. It should have been a number between 1 and $filecount." && return 2
	fi
	filepath=$(echo $files | cut -f$fnumber -d " ")
	if [ $? -ne 0 ] || [ ! -f $filepath ]; then
		echo "File not found"
		return 4
	else
		git diff $filepath
	fi
}

list_options () {
	echo -e "\nGit helper. Available commands:\n"
	echo "  s)git status"
	echo "  l) git log --oneline"
	echo "  aa) git add ."
	echo "  ac) git add . && git commit -m \"[prompt for message]\""
	echo "  acp) git add . && git commit -m && git push -u"
	echo "  c) git commit -m \"[prompt for message]\""
	echo "  am) git commit --amend -m \"[prompt for message]\" (amend last commit message)"
	echo "  rhc) git reset --hard && git clean -df (reset hard and delete untracked files)"
	echo "  d) git diff, choosing from a list of files"
	echo "  cs) print cheat sheet to screen"
	echo "  csq) print cheat sheet to screen and quit"
	# echo "push -u origin main" 
	# echo "  pull) pull origin main"
	echo ""
}

quit () {
	do_quit="true"
}

do_quit=false
message=""

while [ "$do_quit" != "true" ]; do
	read -p "Command (s/l/aa/ac/acp/c/am/rhc/d/cs/csq), help(h) or quit(q): " option
	echo ""
	case $option in
	  s) status;;
	  l) log;;
	  aa) add_all;;
	  ac) add_all_and_commit;;
	  acp) add_all_commit_push;;
	  c) commit;;
	  am) commit_ammend;;
	  rhc) reset_hard;;
	  d) diff;;
	  cs) print_cheat_sheet;;
	  csq) print_cheat_sheet; quit;;
	  h) list_options;;
	  q) quit;;
	  *) echo "Invalid option"; list_options;;
	esac
done

