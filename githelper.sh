#!/bin/bash

MAX_OPTIONS=20

status_command_only () {
	git status -u
}

status () {
	status_command_only && echo "" 
}

log () {
	git log --oneline && echo "" 
}

add_all () {
	git add . && echo "" && status 
}

add_all_and_commit () {
	git add . && echo "" && commit && echo "" && status
}

add_all_commit_push () {
	git add . && echo "" && commit && echo "" && push && echo "" && status
}

reset_hard () {
	git reset --hard && echo "" && git clean -df && echo "" 
}

push () {
	remotes=$(git remote)
	choose_option "$remotes" "Choose remote: " "No remotes configured. Aborting push command."
	ret_code=$?; [ $? -ne 0 ] && return $ret_code
	remote=$option
	branches=$(git branch | sed -e "s/^[* ] //")
	curr_branch=$(git branch --show-current)
	choose_option "$branches" "Choose branch to push. Default is current local branch \"$curr_branch\"." "No branches found. Aborting push command." "$curr_branch"
	ret_code=$?; [ $? -ne 0 ] && return $ret_code
	branch=$option
	confirm "About to run: git push -u $remote $branch." && git push -u $remote $branch && echo ""
	return $?
}

#$1 is the message. E.g.: "The following command will run: git push -u $remote $branch."
confirm () {
	echo -n "$1"
	read -p " Confirm? (y/n)" confirm
	conf_low=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
	if [[ "$conf_low" == "y" ]]; then
		return 0
	else
		echo -e "Cancelled by user request"
		return 1
	fi
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
	print_args "Create local branch and switch to it" "git checkout -b [branch]"
	print_args "List remote branches" "git branch -r"
	print_args "Push local branch to remote, create if needed" "git push -u [remote] [branch]"
	print_args "Pull remote branch to local" "git pull [remote] [branch]"
	print_args "Switch to another branch" "git switch [branch]"
	print_args "Merge into current branch, squashing other branch commits" " git merge --squash [other_branch]"
	print_args "Solve merge conflict by accepting other branch's version" "git checkout --theirs <file name>; git add <file name>"
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
	print_args "Checkout PR locally" "git fetch origin pull/PR_NUMBER/head:branch-name"
	# echo -e "Push branch to remote, create if needed:\npush -u origin main\n\n" 
	# echo "  pull) pull origin main"
}

diff_scripts () {
	diff ".*\.gd|.*\.cs|.*\.sh|.*\.bat"
}

diff () {
	files=$(git status -u | grep -Ee "^.*(modified:|added:|removed:).*$" | sed -e "s/.* //")
	if [ "$1" != "" ]; then
		files=$(git status -u | grep -Ee "^.*(modified:|added:|removed:).*$" | grep -Ee ".*\.cs|.*\.gd" | sed -e "s/.* //")
		#files=$(echo -e "$files" | grep -e "$1")
	else
		files=$(git status -u | grep -Ee "^.*(modified:|added:|removed:).*$" | sed -e "s/.* //")
	fi
	choose_option "$files" "Choose desired file"
	if [ $? -ne 0 ]; then
		return 1
	elif  [ ! -f $option ]; then
		echo "File not found"
		return 2
	fi
	git diff HEAD $option
}

apply_pr () {
	echo -e "\nRemember to be at the correct branch and reset working copy tracked files\n(git reset --hard)\n"
	read -p "Confirm? (y/n): " pr_conf
	[ "$pr_conf" != "y" ] && [ "$pr_conf" != "Y" ] && echo "Aborted." && return 4
	echo -e "\nEnter pull request URL (e.g. https://github.com/godotengine/godot/pull/1234):"
	read pr_url
	echo ""
	pr_pattern="^.*github\\.com.*\\/pull\\/[0-9]+$"
	echo "$pr_url" | grep -Pe "$pr_pattern" 2>&1 > /dev/null
	[ $? -ne 0 ] && echo -e "Pull request URL: $pr_url\ndoes not match PR pattern: \"$pr_pattern\".\nAborting" && return 1
	patch_path="/tmp/$(date '+%Y%m%d_%H%M%S').patch"
	curl -L "$pr_url".patch -o "$patch_path"
	[ $? -ne 0 ] && echo "Patch could not be downloaded. Aborting" && return 1
	echo -e "\nDownloaded patch file to $patch_path."
	grep "$patch_path" -e "^diff --git" 2>&1 > /dev/null
	[ $? -ne 0 ] && echo -e "\nPatch file contents did not match expected pattern. Aborting." && return 2
	echo -e "\nApplying patch file..."
	git apply "$patch_path"
	result_code=$?
	[ $result_code -eq 0 ] && echo -e "\nPatch successfully applied." && return 0
	echo -e "\ngit apply $patch_file: failed with error code $return_code" && return $return_code
}

# $1 is the options, one per line
# $2 is the selection message. E.g.: "Choose desired file"
# $3 is message if no options were provided. E.g.: "No remotes configured. Aborting push command."
# $4 is the default option. E.g. "main"
choose_option () {
	option_count=$(echo -e "$1" | wc -l)

	default_option="$4"
	default_option_number=1
	has_default=false
	default_option_message=""
	if [ "$default_option" != "" ]; then
		for option_str in $1; do
			if [ "$option_str" == "$default_option" ]; then
				has_default=true
				default_option_message=" or ENTER for default"
				break
			fi
			let default_option_number=$default_option_number+1
		done
	fi
			
	[ $option_count -eq 0 ] && echo -e "$3" && return 3
	[ $option_count -eq 1 ] && option=$(echo "$1" | cut -f1 -d " ") && return 0
	i=0
	limited=0
	for option in $1; do
		let i=$i+1
		echo "$i - $option"
		if [ $i -eq $MAX_OPTIONS ]; then
			let ommited_count=$option_count-$MAX_OPTIONS
			echo "Max options reached ($MAX_OPTIONS). Omitting last $ommited_count options"
			break
		fi
	done
	echo ""
	echo "$2"
	read -p "(1 - $option_count)$default_option_message: " opt_number
	num_regex="^[0-9]+$"
	if [ "$has_default" == "true" ]; then
		opt_number=$default_option_number
	fi
	if ! [[ $opt_number =~ $num_regex ]] ; then
		echo "Invalid option: $opt_number. Not a number."
		return 1
	fi
	if [ $opt_number -lt 1 ] || [ $opt_number -gt $option_count ]; then
		echo "Not in range: $opt_number. It should have been a number between 1 and $option_count." && return 2
	fi
	value=$(echo $1 | cut -f$opt_number -d " ")
	if [ $? -ne 0 ]; then
		echo "Error selecting option"
		return 4
	fi	
	option="$value"
}

list_options () {
	echo -e "\nGit helper. Available commands:\n"
	echo "  s)git status -u"
	echo "  l) git log --oneline"
	echo "  aa) git add ."
	echo "  ac) git add . && git commit -m \"[prompt for message]\""
	echo "  acp) git add . && git commit -m && git push -u"
	echo "  apr) apply patch from pull request"
	echo "  c) git commit -m \"[prompt for message]\""
	echo "  p) git push, choosing from a list of remotes and branches"
	echo "  am) git commit --amend -m \"[prompt for message]\" (amend last commit message)"
	echo "  rhc) git reset --hard && git clean -df (reset hard and delete untracked files)"
	echo "  d) git diff, choosing from a list of files"
	echo "  ds) git diff scripts only (*.gd, *.cs, *.sh, *.bat), choosing from a list of files"
	echo "  cs) print cheat sheet to screen"
	echo "  csq) print cheat sheet to screen and quit"
	echo ""
}

quit () {
	do_quit="true"
}

do_quit=false
message=""
option=""

while [ "$do_quit" != "true" ]; do
	echo ""
	read -p "Command (s/l/aa/ac/acp/apr/c/p/am/rhc/d/ds/cs/csq), help(h) or quit(q): " option
	echo ""
	case $option in
	  s) status;;
	  l) log;;
	  aa) add_all;;
	  ac) add_all_and_commit;;
	  acp) add_all_commit_push;;
	  apr) apply_pr;;
	  c) commit;;
	  p) push;;
	  am) commit_ammend;;
	  rhc) reset_hard;;
	  d) diff;;
	  ds) diff_scripts;;
	  cs) print_cheat_sheet | less;;
	  csq) print_cheat_sheet; quit;;
	  h) list_options;;
	  q) quit;;
	  *) echo "Invalid option"; list_options;;
	esac
done

