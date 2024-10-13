#!/bin/bash
# This script create boot menu enteries for rolling back to previous snapshots
# TODO:
# Create a way to save or recreate old linux and initrd images so rollback is possible if kernel version changes

SNAPSHOT_DIR="/.snapshots"

#SNAPSHOT_NUM=$(ls $SNAPSHOT_DIR | sed -e 's/ //g' | wc -l)
OS_NAME=$(cat /etc/os-release | grep NAME | head -n 1 | sed -e 's/"//g' | sed -e 's/NAME=//')

#get default boot config file
#DEFAULT_BOOT=$(ls /efi/loader/entries/$(cat /efi/loader/loader.conf | grep default | awk '{print $2}') | grep -v fallback)
LOADER_PATH="/efi/loader/entries"
MACHINE_ID="8ac393902a5049de8b7118c5b19e36ab"

#loop through existing snapshots
for i in $(ls $SNAPSHOT_DIR)
do
	#get date of snapshot to append to boot entry title
	SNAPSHOT_DATE=$(stat /.snapshots/$i | grep Birth | awk 'OFS="_" {print $2,$3}' | sed -e 's/ //g' | sed -e 's/[:.]/_/g' | sed -e 's/\(_[0-9]\+\)$//')

	#echo $SNAPSHOT_DATE
	SNAPSHOT_NAME="${OS_NAME}_SNAPSHOT_${SNAPSHOT_DATE}"
	VERSION=$(ls /.snapshots/${i}/snapshot/usr/lib/modules | head -n 1)
	SORT_KEY="$(echo $OS_NAME | tr '[:upper:]' '[:lower:]')-${VERSION}"

	#copy efi files to appropriate directory
	EFI_PATH_BACK="/8ac393902a5049de8b7118c5b19e36ab/${VERSION}.bak/"
	LINUX="${EFI_PATH_BACK}linux"
	INITRD="${EFI_PATH_BACK}initrd"

	OPTIONS="nvme_load=YES nowatchdog ro rootflags=subvol=/@/.snapshots/${i}/snapshot root=UUID=5e8ba38d-6bd5-406a-9ea8-12517aff3817 ro rootflags=subvol=/@/.snapshots/${i}/snapshot root=UUID=5e8ba38d-6bd5-406a-9ea8-12517aff3817 systemd.machine_id=8ac393902a5049de8b7118c5b19e36ab"

	SNAPSHOT_PATH="${LOADER_PATH}/${SNAPSHOT_NAME}.conf"

	echo "#conf file created by snapshotboot shell script" > $SNAPSHOT_PATH

	#make this dynamically generate somewhat instead of being hardcoded to more easily accomidate different configs
	echo "title	  ${SNAPSHOT_NAME}" >> $SNAPSHOT_PATH
	echo "version     ${VERSION}" >> $SNAPSHOT_PATH
	echo "machine-id  ${MACHINE_ID}" >> $SNAPSHOT_PATH
	echo "sort-key    ${SORT_KEY}" >> $SNAPSHOT_PATH
	echo "options     ${OPTIONS}" >> $SNAPSHOT_PATH
	echo "linux	  ${LINUX}" >> $SNAPSHOT_PATH
	echo "initrd	  ${INITRD}" >> $SNAPSHOT_PATH
done

