#!/bin/bash

MAX_OPTIONS=20

STATUS_MODIFIED=10
STATUS_MODIFIED_DELETED=11
STATUS_NEW_ADDED_MODIFIED_DELETED=12

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
	choose_option "$remotes" "Choose remote: " "No remotes configured. Aborting push command." "" 0 1
	ret_code=$?; [ $? -ne 0 ] && return $ret_code
	remote=$option
	branches=$(git branch | sed -e "s/^[* ] //")
	curr_branch=$(git branch --show-current)
	choose_option "$branches" "Choose branch to push. Default is current local branch \"$curr_branch\"." "No branches found. Aborting push command." "$curr_branch" 0 1
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
	git pull && echo "" 
}


get_commit_message () {
	echo "Type commit message (no quotes):"
	read -p "" message
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
	diff "gd cs sh bat"
}

cycle_command_on_files () {
	local status_to_list="$1" # STATUS_MODIFIED or STATUS_NEW_ADDED_MODIFIED_DELETED
	local extension_filters="$2" # space separated file extensions to filter. E.g.: "sh c java txt"
	local command="$3"
	local enter_to_return="$4"
	local auto_select_single_option="$5"
	local refresh_list_each_cycle="$6" # if 1, find files again after each cycle. Otherwise, reuse file list (faster).

	local files=""
	local files_initialised=0

	while [ 0 -ne 1 ]; do
	
		if [ $files_initialised -eq 0 ] || [ "$refresh_list_each_cycle" == "1" ]; then
			local filter_command=""
			if [ "$extension_filters" != "" ]; then
				local filter_command='| grep -Ee "'
				for extension in $extension_filters; do
					filter_command="$filter_command"'.*\.'"$extension"'|'
				done
				filter_command="$filter_command"'"'
				filter_command=$(echo "$filter_command" | sed -e "s/\(.*\)|/\1/")
			fi
			
			file_list_command=""
			if [ "$status_to_list" == "$STATUS_MODIFIED" ]; then
				file_list_command='git ls-files --modified'
			elif [ "$status_to_list" == "$STATUS_MODIFIED_DELETED" ]; then
				file_list_command='git ls-files --modified --deleted'
			else
			elif [ "$status_to_list" == "$STATUS_NEW_ADDED_MODIFIED_DELETED" ]; then
				file_list_command='git ls-files --modified --deleted --other --exclude-standard; git diff --name-only --cached'
			else
				echo "Status type not found: *$status_to_list*"
			fi
			file_list_command="$file_list_command $filter_command"

			files=$(( eval "$file_list_command" ) | sort -u)
			
			files_initialised=1
		fi
		
	
		if [ "$files" == "" ]; then
			echo "No relevant files found "
			break
		fi
		
		choose_option "$files" "Choose desired file (or only ENTER to cancel)" "" "" "$enter_to_return" "$auto_select_single_option"
		local return_code=$?
		if [ $return_code -eq 0 ] && [ "$option" == "" ]; then
			break
		fi
		if [ $return_code -ne 0 ]; then
			echo "Error choosing option (code: $return_code)"
			continue
		fi
		if  [ ! -f $option ]; then
			echo "File not found"
			continue
		fi
		eval $command $option
		echo ""
		[ $option_count -eq 1 ] && break
	done
}

restore_single_file () {
	local status_to_list=$STATUS_MODIFIED_DELETED
	local extension_filters=""
	local command="git restore"
	local enter_to_return=1
	local auto_select_single_option=0
	local refresh_list_each_cycle=1
		
	cycle_command_on_files "$status_to_list" "$extension_filters" "$command" "$enter_to_return" "$auto_select_single_option" "$refresh_list_each_cycle"
}

diff () {
	local status_to_list=$STATUS_MODIFIED
	local extension_filters="$1"
	local command="git diff HEAD"
	local enter_to_return=1
	local auto_select_single_option=1
	local refresh_list_each_cycle=0
	
	cycle_command_on_files "$status_to_list" "$extension_filters" "$command" "$enter_to_return" "$auto_select_single_option" "$refresh_list_each_cycle"
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
# $5 if $5 is 1 and $4 (deafault option) is empty, just pressing ENTER returns code 0 and empty $option, otherwise returns code 4 (option not found)
# $6 if 1 and option_count = 1, automatically choose that option and return with code 0
choose_option () {
	option_count=$(echo -e "$1" | wc -l)
	default_option="$4"
	default_option_number=1
	has_default=false
	default_option_message=""
	auto_select_single_option=$6
	local cancel_on_enter=$5
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
			
	[ $option_count -eq 0 ] && echo -e "$3" && return 3 # 3 = no options supplied
	
	[ $option_count -eq 1 ] && [ "$auto_select_single_option" == "1" ] && option=$(echo "$1" | cut -f1 -d " ") && return 0
	
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
	if [ "$opt_number" == "" ] && [ "$cancel_on_enter" == "1" ]; then
		option=""
		return 0
	fi
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
	echo "	pl) git pull"
	echo "  am) git commit --amend -m \"[prompt for message]\" (amend last commit message)"
	echo "  rsf) git restore single file, choosing from a list of files"
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
option_count=0

while [ "$do_quit" != "true" ]; do
	echo ""
	echo "Command (s/l/aa/ac/acp/apr/c/p/pl/am/rsf/rhc/d/ds/cs/csq), help(h) or quit(q):"
	read -p "" option
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
	  pl) pull;;
	  am) commit_ammend;;
	  rsf) restore_single_file;;
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

