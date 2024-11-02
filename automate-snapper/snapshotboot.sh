#!/bin/bash
# This script create boot menu enteries for rolling back to previous snapshots
# TODO:
# Create a way to save or recreate old linux and initrd images so rollback is possible if kernel version changes
# change so this file create entry when snapshot is taken

#get config file
source "./config"
TOTAL_ENTERIES=$((TIMELINE_ENTRY_AMOUNT + UPDATE_ENTRY_AMOUNT))
UPDATE_ENTERIES=$(snapper -c config list | grep -E "pre|post" | tail -n $((UPDATE_ENTRY_AMOUNT * 2)))
TIMELINE_ENTRY=$(snapper -c config list | grep -E "single" | tail -n $TIMELINE_ENTRY_AMOUNT)

#get os info
OS_NAME=$(cat /etc/os-release | grep NAME | head -n 1 | sed -e 's/"//g' | sed -e 's/NAME=//')
LOADER_PATH="/efi/loader/entries"
MACHINE_ID="8ac393902a5049de8b7118c5b19e36ab"
EFI_PATH_BACK="/8ac393902a5049de8b7118c5b19e36ab/${VERSION}_bak/"
LINUX="${EFI_PATH_BACK}linux"
INITRD="${EFI_PATH_BACK}initrd"

#create copy of current kernel to boot into
version_backup() {
    if [[ ! -d "/efi${EFI_PATH_BACK}" ]]
    then
        rsync -a --delete /efi/8ac393902a5049de8b7118c5b19e36ab/$VERSION "/efi/8ac393902a5049de8b7118c5b19e36ab/${VERSION}_back"
    fi
}


create_snapshot_entry() {
       echo "title	  ${SNAPSHOT_NAME}" >> $SNAPSHOT_DIR
       echo "version     ${VERSION}" >> $SNAPSHOT_DIR
       echo "machine-id  ${MACHINE_ID}" >> $SNAPSHOT_DIR
       echo "sort-key    ${SORT_KEY}" >> $SNAPSHOT_DIR
       echo "options     ${OPTIONS}" >> $SNAPSHOT_DIR
       echo "linux	  ${LINUX}" >> $SNAPSHOT_DIR
       echo "initrd	  ${INITRD}" >> $SNAPSHOT_DIR
}

#remove old entries
#rm "$LOADER_PATH/$(ls $LOADER_PATH | grep -E "timeline|pre|post")"
for old in $(ls $LOADER_PATH | grep -E "timeline|pre|post")
do
    echo "Removing $old"
    rm "$LOADER_PATH/$old"
done

NUM=$(echo "$UPDATE_ENTRIES" | grep "pre" | wc -l)
while [[ NUM -gt 0 ]]
do
    PRE=$(echo "$UPDATE_ENTRIES" | grep "pre" | sed -n "$num"p)
    VERSION=$(ls $SNAPSHOT_DIR/${PRE}/snapshot/usr/lib/modules | head -n 1)
    SORT_KEY="$(echo $OS_NAME | tr '[:upper:]' '[:lower:]')-${VERSION}"
    SNAPSHOT_DATE=$(stat $SNAPSHOT_DIR/$(echo "$PRE" | awk '{print $1}') | 
        grep Birth | 
        awk 'OFS="_" {print $2,$3}' | 
        sed -e 's/ //g' | 
        sed -e 's/[:.]/_/g' | 
        sed -e 's/\(_[0-9]\+\)$//')
    SNAPSHOT_NAME="${OS_NAME}_PRE_${SNAPSHOT_DATE}"
    version_backup
    create_snapshot_entry

    POST=$(echo "$UPDATE_ENTRIES" | grep "post" | sed -n "$num"p)
    VERSION=$(ls $SNAPSHOT_DIR/${POST}/snapshot/usr/lib/modules | head -n 1)
    SORT_KEY="$(echo $OS_NAME | tr '[:upper:]' '[:lower:]')-${VERSION}"
    SNAPSHOT_DATE=$(stat /.snapshots/$(echo "$PRE" | awk '{print $1}') | 
        grep Birth | 
        awk 'OFS="_" {print $2,$3}' | 
        sed -e 's/ //g' | 
        sed -e 's/[:.]/_/g' | 
        sed -e 's/\(_[0-9]\+\)$//')
    SNAPSHOT_NAME="${OS_NAME}_PRE_${SNAPSHOT_DATE}"

    NUM=$((NUM - 1))
done


#   #have seperate loop for timeline and pre/post snapshots
#   #loop through existing snapshots
#   for i in $(ls $SNAPSHOT_DIR)
#   do
#       #get date of snapshot to append to boot entry title
#       SNAPSHOT_DATE=$(stat /.snapshots/$i | grep Birth | awk 'OFS="_" {print $2,$3}' | sed -e 's/ //g' | sed -e 's/[:.]/_/g' | sed -e 's/\(_[0-9]\+\)$//')
#
#       #echo $SNAPSHOT_DATE
#       SNAPSHOT_NAME="${OS_NAME}_SNAPSHOT_${SNAPSHOT_DATE}"
#       VERSION=$(ls /.snapshots/${i}/snapshot/usr/lib/modules | head -n 1)
#       SORT_KEY="$(echo $OS_NAME | tr '[:upper:]' '[:lower:]')-${VERSION}"
#
#       #copy efi files to appropriate directory
#       EFI_PATH_BACK="/8ac393902a5049de8b7118c5b19e36ab/${VERSION}.bak/"
#       LINUX="${EFI_PATH_BACK}linux"
#       INITRD="${EFI_PATH_BACK}initrd"
#
#       OPTIONS="nvme_load=YES nowatchdog ro rootflags=subvol=/@/.snapshots/${i}/snapshot root=UUID=5e8ba38d-6bd5-406a-9ea8-12517aff3817 ro rootflags=subvol=/@/.snapshots/${i}/snapshot root=UUID=5e8ba38d-6bd5-406a-9ea8-12517aff3817 systemd.machine_id=8ac393902a5049de8b7118c5b19e36ab"
#
#       SNAPSHOT_PATH="${LOADER_PATH}/${SNAPSHOT_NAME}.conf"
#
#       echo "#conf file created by snapshotboot shell script" > $SNAPSHOT_PATH
#
#       #make this dynamically generate somewhat instead of being hardcoded to more easily accomidate different configs
#       echo "title	  ${SNAPSHOT_NAME}" >> $SNAPSHOT_PATH
#       echo "version     ${VERSION}" >> $SNAPSHOT_PATH
#       echo "machine-id  ${MACHINE_ID}" >> $SNAPSHOT_PATH
#       echo "sort-key    ${SORT_KEY}" >> $SNAPSHOT_PATH
#       echo "options     ${OPTIONS}" >> $SNAPSHOT_PATH
#       echo "linux	  ${LINUX}" >> $SNAPSHOT_PATH
#       echo "initrd	  ${INITRD}" >> $SNAPSHOT_PATH
#   done
#
