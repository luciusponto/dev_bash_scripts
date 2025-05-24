 #!/bin/bash
GODOT=~/AppData/Roaming/Godot/app_userdata/Godots/versions/Godot_v4_4-stable_win64_exe/Godot_v4.4-stable_win64.exe
BUTLER=~/AppData/Roaming/itch/apps/butler/butler.exe

SETTINGS_DIR=.godot_to_itch
BUILD_NUMBER_FILE=$SETTINGS_DIR/buildnumber.txt
ITCH_DATA_FILE=$SETTINGS_DIR/itch-butler.txt

ALL_PLATFORMS="win64 html5"


usage () {
	echo -e "\nUsage:\n"
	script=$(basename $0)
	echo -e "$script [platform1,platform2,...]\n"
	echo "platform can be win64, html5 or all"
	echo "if no arguments are supplied and $PLATFORMS_FILE exists, platforms will come from it"
	echo "e.g.: $script win64,html5"
	echo "e.g.: $script all"
	exit $1
}

build_deploy () {
	platf=$1

	if [ "$platf" == "html5" ]; then
		preset=Web
		channel=html5
		file=index.html
	fi

	if [ "$platf" == "win64" ]; then
		preset="Windows Desktop"
		channel=win-64
		file=game.exe
	fi
	
	[ "$preset" == "" ] && echo -e "\nBug: platform $platf not correctly setup. Please edit the script to add this platform." && exit 11
	
	build_dir=.build/$channel

	if [ ! -d $build_dir ]; then
		echo "Creating $build_dir"
		mkdir -p $build_dir
	fi

	[ -d $build_dir ] && rm $build_dir/*
	 
	$GODOT --headless --export-release "$preset" $build_dir/$file
	 
	$BUTLER push $build_dir $itch_path:$channel --userversion-file $BUILD_NUMBER_FILE
}

[ ! -f project.godot ] && echo -e "\nproject.godot not found. Run from a Godot project root." && exit 4

if [ ! -d $SETTINGS_DIR ]; then
	mkdir $SETTINGS_DIR
	[ ! -d $SETTINGS_DIR ] && echo -e "\nCould not create $SETTINGS_DIR" && exit 9
fi

if [ ! -f $ITCH_DATA_FILE ]; then
	echo "Could not find itch data file: $ITCH_DATA_FILE"
	echo "Create this file in the root of the Godot project"
	echo "And add a line with: itch:[itch username]/[itch game name (from url)]"
	echo "E.g.: itch:luciusponto/journey-to-a-tiny-world"
	exit 1
fi

if [ "$1" == "all" ]; then
	platforms=$ALL_PLATFORMS
else
	platforms=$(echo "$@" | sed -e "s/,/ /g")
fi

for platform in $platforms; do
	is_valid=0
	for valid_platf in $ALL_PLATFORMS; do
		[ "$platform" == "$valid_platf" ] && is_valid=1 && break
	done
	if [ $is_valid -ne 1 ]; then
		echo -e "\nInvalid platform: $platform" && exit 10
	fi
done

if [ ! -f $BUILD_NUMBER_FILE ]; then
	echo 0.1.-1 > $BUILD_NUMBER_FILE
	[ ! -f $BUILD_NUMBER_FILE ] && echo -e "\nCould not create $BUILD_NUMBER_FILE" && exit 6
fi

build_number=$(head -n1 $BUILD_NUMBER_FILE)
echo $build_number | grep -Pe "[0-9]+\.[0-9]+\.[\-]{0,1}[0-9]+" 2>&1 > /dev/null
[ $? -ne 0 ] && echo -e "\nInvalid build number. Should be semantic, i.e. in the format 1.0.0" && exit 7

major_minor=$(echo $build_number | sed -e "s/[\-]*[0-9]*$//")
patch_version=$(echo $build_number | sed -e "s/^.*\.//")

new_patch_version=$((patch_version+1))
new_version_number=$major_minor$new_patch_version

echo "Version number: $build_number -> $new_version_number"
echo $new_version_number > $BUILD_NUMBER_FILE

itch_path=$(grep $ITCH_DATA_FILE -e "^itch:" | sed -e "s/^itch.//")
echo "Itch path: [$itch_path]"

build_error=0

for platform in $platforms; do
	build_deploy $platform
	last_err=$?
	[ $last_err -ne 0 ] && build_error=$last_err
done

echo -e "\nFinished building version $new_version_number"
[ $build_error -ne 0 ] && echo "Error code $build_error"

  