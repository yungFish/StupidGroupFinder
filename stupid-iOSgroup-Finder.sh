#!/bin/bash

##############################################################################
#
# Welcome to Stupid MobileDevice Group Finder!
#
# This script was designed to work in two parts. First, to check the three
# deliverables within Jamf Pro to find which Smart Device Groups are
# effectively being used as targets then second, to cross-reference those
# targeted against all existing groups. This script will (hopefully) help 
# you locate any Smart Device Groups in your environment that are adding
# unnecessary work for your server. Once found, the un-targeted groups may 
# be re-purposed using 'Stupid Groups' from Mike Levenick (link below) 
# which lets you convert a Smart Device Group into a Static Device Group
# or an Advanced Mobile Device Search depending on the group's purpose.
#
# Stupid Groups link: https://github.com/mike-levenick/stupid-groups/releases
#
##############################################################################
#	Clean up and set variables
##############################################################################

JSSAdmin="apiuser"
JSSPassw="password"
JSSURL="https://yourinstancename.jamfcloud.com"
logDate="$(date '+%Y-%m-%d_%H-%M-%S')"
logFile="/var/log/stupid-iOSGroup-Finder_${logDate}.txt"
IFS=','

touch $logFile

##############################################################################
#	Define function to append target list and set consistent logFile output
##############################################################################

appendTargets () {
	
	[[ -n "$TARGETSLIST" ]] && smartGroupTargetsList="${smartGroupTargetsList}${TARGETSLIST}${IFS}"
	[[ -n "$XCLUDESLIST" ]] && smartGroupTargetsList="${smartGroupTargetsList}${XCLUDESLIST}${IFS}"
	
	[[ -n "$TARGETSLIST" && -n "$XCLUDESLIST" ]] && echo "$1(ID=$2) Target Group IDs: ${TARGETSLIST} - Exclusion Group IDs: ${XCLUDESLIST}" >> $logFile 
	[[ -n "$TARGETSLIST" && -z "$XCLUDESLIST" ]] && echo "$1(ID=$2) Target Group IDs: ${TARGETSLIST}" >> $logFile 
	[[ -z "$TARGETSLIST" && -n "$XCLUDESLIST" ]] && echo "$1(ID=$2) Exclusion Group IDs: ${XCLUDESLIST}" >> $logFile 
	#[[ -z "$TARGETSLIST" && -z "$XCLUDESLIST" ]] && echo "$1(ID=$2) - <n/a>" >> $logFile
	
}

##############################################################################
#	Begin script
##############################################################################

##### MOBILECONFIGS ######

echo -e "\n$(date '+%H:%M:%S') - Finding mobileconfig Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

configIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/mobiledeviceconfigurationprofiles | xmllint --xpath '//configuration_profile/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $configIDList; do
	
	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/mobiledeviceconfigurationprofiles/id/$i | xmllint --xpath '//configuration_profile/scope/mobile_device_groups/mobile_device_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/mobiledeviceconfigurationprofiles/id/$i | xmllint --xpath '//configuration_profile/scope/exclusions/mobile_device_groups/mobile_device_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	
	appendTargets 'Config' $i
	
done

##### MOBILE DEVICE APPS ######

echo -e "\n$(date '+%H:%M:%S') - Finding Mobile Device App Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

iOSappIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/mobiledeviceapplications | xmllint --xpath '//mobile_device_application/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $iOSappIDList; do
	
	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/mobiledeviceapplications/id/$i | xmllint --xpath '//mobile_device_application/scope/mobile_device_groups/mobile_device_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/mobiledeviceapplications/id/$i | xmllint --xpath '//mobile_device_application/scope/exclusions/mobile_device_groups/mobile_device_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	
	appendTargets 'iOSApp' $i
	
done

##### EBOOKS LOL ######

echo -e "\n$(date '+%H:%M:%S') - Finding eBook Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

ebooksIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/ebooks | xmllint --xpath '//ebook/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $ebooksIDList; do

	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/ebooks/id/$i | xmllint --xpath '//ebook/scope/mobile_device_groups/mobile_device_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/ebooks/id/$i | xmllint --xpath '//ebook/scope/exclusions/mobile_device_groups/mobile_device_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )

	appendTargets 'Ebooks' $i

done

##### COLLECT ALL SMART MOBILE DEVICE GROUPS IN ARRAY #####

groupIDsArray=( $( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/mobiledevicegroups | xmllint --xpath '//mobile_device_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' ) )

###### REMOVE GROUPS TARGETED MULTIPLE TIMES RESULTING IN DUPLICATE NAMES ######

echo -e "\n$(date '+%H:%M:%S') - Removing duplicate group targets..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

# set counter variable and create array
z=0 ; smartGroupTargetsArray=()

# assign list values to array for easier comparison
for grp in $smartGroupTargetsList; do
	smartGroupTargetsArray[$z]="${grp}"
	(( z+=1 ))
done

# (re)set counter variables and create empty $uniqueArray to store unique group names
uniqueArray=() ; z=0 ; s=0

# Go thru each $smartGroupTargetsArray element and compare that group name to the previously
# searched groups. if it's not in the 'trimmed' list, assign our newly found
# 'non-duplicate' value to the next available index in the array
while [ $z -lt ${#smartGroupTargetsArray[@]} ]; do
	
	d=0 ; duplicate=""
	while [[ $d -lt ${#uniqueArray[@]} && -z "${duplicate}" ]]; do
		[[ "${smartGroupTargetsArray[$z]}" == "${uniqueArray[$d]}" ]] && duplicate="true"
		(( d+=1 ))
	done
	
	if [[ -z "${duplicate}" && -n "${smartGroupTargetsArray[$z]}" ]]; then
		uniqueArray[$s]=${smartGroupTargetsArray[$z]}
		(( s+=1 ))
	fi
	
	(( z+=1 ))
done

###### DETERMINE FINAL LIST OF UNTARGETED GROUPS ######

# set counter variables and create empty $noTargetsArray to store untargeted groups
noTargetsArray=() ; B=0 ; OG=0
while [ $OG -lt ${#groupIDsArray[@]} ]; do
	
	SA=0 ; targets=""
	while [[ $SA -lt ${#uniqueArray[@]} && -z "${targets}" ]]; do
		[[ "${groupIDsArray[$OG]}" == "${uniqueArray[$SA]}" ]] && targets="found"	
		(( SA+=1 ))
	done
	
	if [[ -z "${targets}" ]]; then
		noTargetsArray[$B]=${groupIDsArray[$OG]}
		(( B+=1 ))
	fi

	(( OG+=1 ))
done

echo -e "\n$(date '+%H:%M:%S') - Final output of untargeted groups!" >> $logFile
echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

# Output to terminal for simplicity
echo -e "\nUntargeted Groups:"

i=0
while [ $i -lt ${#noTargetsArray[@]} ]; do
#	echo "$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/mobiledevicegroups/id/${noTargetsArray[$i]} | xmllint --xpath '//mobile_device_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' ) (GroupID: ${noTargetsArray[$i]})" >> $logFile
	echo "GroupID: ${noTargetsArray[$i]}" >> $logFile
	
	# Output to terminal for simmplicity
	echo "$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/mobiledevicegroups/id/${noTargetsArray[$i]} | xmllint --xpath '//mobile_device_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' ) (GroupID: ${noTargetsArray[$i]})"
	
	(( i+=1 ))
done

exit 0