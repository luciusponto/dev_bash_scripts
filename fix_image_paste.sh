XLCIP_SOURCE="$HOME/.config/blender/5.0/scripts/addons/imagepaste/imagepaste/clipboard/linux/bin/xclip"
BLENDER_CONFIG="$HOME/.config/blender"
IMAGE_PASTE_BIN_SUBPATH="scripts/addons/imagepaste/imagepaste/clipboard/linux/bin"

blender_versions_paths=$(find "$BLENDER_CONFIG" -mindepth 1 -maxdepth 1 -type d)
for version_path in $blender_versions_paths; do
	echo -n "Version found: $(basename $version_path). "
	addon_path="$version_path"/"$IMAGE_PASTE_BIN_SUBPATH"
	find "$addon_path" -type d > /dev/null 2>&1
	addon_exists=$?
	if [ $addon_exists -eq 0 ]; then
		echo -n "Has Image Paste addon. "
		xclip_path="$addon_path"/xclip
		find $xclip_path -type f > /dev/null 2>&1
		xclip_found=$?
		if [ $xclip_found -ne 0 ]; then
			echo -n "Fixing. "
			message=$(cp $XLCIP_SOURCE $addon_path 2>&1)
			if [ $? -eq 0 ]; then
				echo -n "Fixed. "
			else
				echo -n -e "Failed with message:\n$message. \n"
			fi
		else
			echo -n "xclip found. "
		fi
	else
		echo -n "Doesn't have Image Paste addon. "
	fi
	echo ""
done
