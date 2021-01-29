#!/bin/bash

##############################################################################
#
# Welcome to Stupid Computer Group Finder!
#
# This script was designed to work in two parts. First, to check the six
# deliverables within Jamf Pro to find which Smart Computer Groups are
# effectively being used as targets then second, to cross-reference those
# targeted against all existing groups. This script will (hopefully) help 
# you locate any Smart Computer Groups in your environment that are adding
# unnecessary work for your server. Once found, the un-targeted groups may 
# be re-purposed using 'Stupid Groups' from Mike Levenick (link below) 
# which lets you convert a Smart Computer Group into a Static Computer Group
# or an Advanced Computer Search depending on the group's purpose.
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
logFile="/var/log/stupid-ComputerGroup-Finder_${logDate}.txt"
IFS=','

touch $logFile

##############################################################################
#	Define function to append target list and set consistent logFile output
##############################################################################

appendTargets () {
	
	[[ -n "$TARGETSLIST" ]] && smartGroupTargetsList="${smartGroupTargetsList}${TARGETSLIST},"
	[[ -n "$XCLUDESLIST" ]] && smartGroupTargetsList="${smartGroupTargetsList}${XCLUDESLIST},"

	[[ -n "$TARGETSLIST" && -n "$XCLUDESLIST" ]] && echo "$1(ID=$2) Target Groups: ${TARGETSLIST} - Exclusions: ${XCLUDESLIST}" >> $logFile 
	[[ -n "$TARGETSLIST" && -z "$XCLUDESLIST" ]] && echo "$1(ID=$2) Target Groups: ${TARGETSLIST}" >> $logFile 
	[[ -z "$TARGETSLIST" && -n "$XCLUDESLIST" ]] && echo "$1(ID=$2) Exclusions: ${XCLUDESLIST}" >> $logFile 
#	[[ -z "$TARGETSLIST" && -z "$XCLUDESLIST" ]] && echo "$1(ID=$2) - <n/a>" >> $logFile

}

##############################################################################
#	Begin script
##############################################################################

###### POLICIES ######

echo -e "\n$(date '+%H:%M:%S') - Finding Policy Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

policyIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/policies | xmllint --xpath '//policy/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $policyIDList; do

	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/policies/id/$i | xmllint --xpath '//policy/scope/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/policies/id/$i | xmllint --xpath '//policy/scope/exclusions/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )
	
	appendTargets 'Policy' $i
	
done

##### MOBILECONFIGS ######

echo -e "\n$(date '+%H:%M:%S') - Finding mobileconfig Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

configIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/osxconfigurationprofiles | xmllint --xpath '//os_x_configuration_profile/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $configIDList; do

	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/osxconfigurationprofiles/id/$i | xmllint --xpath '//os_x_configuration_profile/scope/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/osxconfigurationprofiles/id/$i | xmllint --xpath '//os_x_configuration_profile/scope/exclusions/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )
	
	appendTargets 'Config' $i
 	
done

##### RESTRICTED SOFTWARE ######

echo -e "\n$(date '+%H:%M:%S') - Finding Restricted Software Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

restSWIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/restrictedsoftware | xmllint --xpath '//restricted_software_title/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $restSWIDList; do

	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/restrictedsoftware/id/$i | xmllint --xpath '//restricted_software/scope/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/restrictedsoftware/id/$i | xmllint --xpath '//restricted_software/scope/exclusions/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )

	appendTargets 'RestSW' $i

done

##### MAC APP STORE APPS ######

echo -e "\n$(date '+%H:%M:%S') - Finding Mac App Store App Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

masappIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/macapplications | xmllint --xpath '//mac_application/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $masappIDList; do

	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/macapplications/id/$i | xmllint --xpath '//mac_application/scope/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/macapplications/id/$i | xmllint --xpath '//mac_application/scope/exclusions/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )

	appendTargets 'MASApp' $i
	
done

##### PATCH POLICIES ######

echo -e "\n$(date '+%H:%M:%S') - Finding Patch Policy Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

patchpIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/patchpolicies | xmllint --xpath '//patch_policy/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $patchpIDList; do

	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/patchpolicies/id/$i | xmllint --xpath '//patch_policy/scope/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/patchpolicies/id/$i | xmllint --xpath '//patch_policy/scope/exclusions/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )

	appendTargets 'PatchP' $i
	
done

###### EBOOKS LOL ######

echo -e "\n$(date '+%H:%M:%S') - Finding eBook Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

ebooksIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/ebooks | xmllint --xpath '//ebook/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $ebooksIDList; do

	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/ebooks/id/$i | xmllint --xpath '//ebook/scope/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/ebooks/id/$i | xmllint --xpath '//ebook/scope/exclusions/computer_groups/computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' )

	appendTargets 'Ebooks' $i

done

##### COLLECT ALL SMART COMPUTER GROUPS IN ARRAY #####

groupNamesArray=( $( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/computergroups | xmllint --xpath '//computer_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' ) )

###### REMOVE GROUPS TARGETED MULTIPLE TIMES RESULTING IN DUPLICATE NAMES ######

echo -e "\n$(date '+%H:%M:%S') - Removing duplicate group targets..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

# set counter variable and create array
z=0 ; smartGroupTargetsArray=()

# assign list values to array for easier comparison
for grp in $smartGroupTargetsList; do
	smartGroupTargetsArray[$z]=${grp}
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
while [ $OG -lt ${#groupNamesArray[@]} ]; do
	
	SA=0 ; targets=""
	while [[ $SA -lt ${#uniqueArray[@]} && -z "${targets}" ]]; do
		[[ "${groupNamesArray[$OG]}" == "${uniqueArray[$SA]}" ]] && targets="found"	
		(( SA+=1 ))
	done
	
	if [[ -z "${targets}" ]]; then
		noTargetsArray[$B]=${groupNamesArray[$OG]}
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
	echo "${noTargetsArray[$i]}" >> $logFile
	
	# Output to terminal for simmplicity
	echo "${noTargetsArray[$i]}"
	
	(( i+=1 ))
done

exit 0