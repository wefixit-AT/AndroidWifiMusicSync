#!/bin/bash

source ./config.sh
source $LIB_FOLDER/checkExitStatus.sh
source $LIB_FOLDER/logging.sh

# change field separator to new line
IFS=$'\n'

# check if we can reach the phone
ping $IP -c 3 &> /dev/null
if [ $? -ne 0 ]; then
    echo "!!! Can't ping the phone with the IP $IP"
    exit 1
fi

# check if playlist is set correct
if [ ! -f "$PLAYLIST" ]; then
    echo "!!! Please check the PLAYLIST from the config"
    exit 1
fi

# umount phone and delete corrupt files
sudo umount -l "$MNT_DIR" &> /dev/null
umount_return_value=$?
# a return value of 32 from umount mean that i wasn't mounted
if [ $umount_return_value -eq 32 ]; then
    if [ $(ls -A $MNT_DIR) ]; then
        echo "Can't unmount, should we delete the files? \"ctrl+c\" to abort, \"enter\" to delete the files"
        read
        rm -rfv "$MNT_DIR"
        mkdir "$MNT_DIR"
    fi
elif [ $umount_return_value -ne 0 ]; then
    echo "return value is not 0 or 32 so there must be a problem, please debug"
    exit 1
fi

# mount the phone
sshfs $USER@$IP:/extSdCard/Music "$MNT_DIR"
checkExitStatus $? sshfs

# generate duplicated lines
sort "$PLAYLIST" | uniq > "$TMP_FILE"

# generate fileset which should be copied to the phone
cat $PLAYLIST | grep -v EXTINF | grep -v EXTM3U | sed "s/..\/..\/..//g" | sed "s/(/\(/g" > "$TMP_FILE"

echo "There are $(cat $TMP_FILE | wc -l) files to copy to the phone"

# cleanup files which are not in the files list
function checkAgainstTmpFile {
    file=$1
    for i in $(cat $TMP_FILE); do
        i=$(echo $i | rev | cut -d '/' -f 1 | rev);
        if [ "$i" == "$file" ]; then
            return
        fi
    done
    log "Delete on the phone: $file"
    rm "$MNT_DIR/$file"
}

echo "Cleanup files on the phone"
for i in $(ls -1A $MNT_DIR/); do
    checkAgainstTmpFile $i
done

# copy files to the phone
echo "Copying files to the phone"
rsync -r -v --size-only --no-relative --files-from="$TMP_FILE" / "$MNT_DIR"/ &> /dev/null
checkExitStatus $? rsync

# cleanup
rm "$TMP_FILE"
sudo umount "$MNT_DIR"

echo "All files copied, press \"enter\" to exit"
read
