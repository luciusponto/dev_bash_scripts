#!/bin/bash

NOT_GODOT_PROJ_DIR=1

source_path="$@"

copy_file() {
	full_path="$@"
	file=$(basename "$full_path")
	if [ -f $file ]; then
		echo -n "$file already exists; skipped."
	else
		echo -n "Copying file $file"
		cp "$full_path" .
		[ ! -f "$file" ] && echo -n " - failure"
	fi
	echo ""
}

if [ ! -f "project.godot" ]; then
	echo "Error. This is not a Godot project root directory: project.godot not found. Aborting." && exit $NOT_GODOT_PROJ_DIR
fi

echo "Creating directories:"

for folder in $(cat $source_path/folder_structure.txt); do
	echo -n "$folder"
	mkdir -p "$folder"
	[ $? -ne 0 ] && echo -n " - failure"
	echo ""
done

echo ""

for file in .gitignore .gitattributes; do
	copy_file "$source_path/$file"
done
