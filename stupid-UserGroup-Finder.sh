#!/bin/bash

##############################################################################
#
# Welcome to Stupid User Group Finder!
#
# This script was designed to work in two parts. First, to check the three
# deliverables within Jamf Pro to find which Smart User Groups are
# effectively being used as targets then second, to cross-reference those
# targeted against all existing groups. This script will (hopefully) help 
# you locate any Smart User Groups in your environment that are adding
# unnecessary work for your server. Once found, the un-targeted groups may 
# be re-purposed using 'Stupid Groups' from Mike Levenick (link below) 
# which lets you convert a Smart User Group into a Static User Group
# or an Advanced User Search depending on the group's purpose.
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
logFile="/var/log/stupid-UserGroup-Finder_${logDate}.txt"
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

##### VPP INVITATIONS ######

echo -e "\n$(date '+%H:%M:%S') - Finding VPP Invitations Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

VPPinvIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/vppinvitations | xmllint --xpath '//vpp_invitation/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $VPPinvIDList; do
	
	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/vppinvitations/id/$i | xmllint --xpath '//vpp_invitation/scope/jss_user_groups/user_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/vppinvitations/id/$i | xmllint --xpath '//vpp_invitation/scope/exclusions/jss_user_groups/user_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	
	appendTargets 'VPPinv' $i
	
done

##### VPP VOLUME ASSIGNMENTS ######

echo -e "\n$(date '+%H:%M:%S') - Finding VPP Volume Assignment Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

VPPasnIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/vppassignments | xmllint --xpath '//vpp_assignment/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $VPPasnIDList; do
	
	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/vppassignments/id/$i | xmllint --xpath '//vpp_assignment/scope/jss_user_groups/user_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/vppassignments/id/$i | xmllint --xpath '//vpp_assignment/scope/exclusions/jss_user_groups/user_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	
	appendTargets 'VPPasn' $i
	
done

##### EBOOKS LOL ######

echo -e "\n$(date '+%H:%M:%S') - Finding eBook Smart Group targets and exclusions..." >> $logFile
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" >> $logFile

ebooksIDList=$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/ebooks | xmllint --xpath '//ebook/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' )

for i in $ebooksIDList; do

	TARGETSLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/ebooks/id/$i | xmllint --xpath '//ebook/scope/jss_user_groups/user_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )
	XCLUDESLIST=$( curl -ksu ${JSSAdmin}:${JSSPassw} ${JSSURL}/JSSResource/ebooks/id/$i | xmllint --xpath '//ebook/scope/exclusions/jss_user_groups/user_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' )

	appendTargets 'Ebooks' $i

done

##### COLLECT ALL SMART USER GROUPS IN ARRAY #####

groupIDsArray=( $( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/usergroups | xmllint --xpath '//user_group/id' - | sed -e $'s/\<id\>//g' -e $'s/\<\/id\>/,/g' -e $'s/\,$//' ) )

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
#	echo "$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/usergroups/id/${noTargetsArray[$i]} | xmllint --xpath '//user_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' ) (GroupID: ${noTargetsArray[$i]})" >> $logFile
	echo "GroupID: ${noTargetsArray[$i]}" >> $logFile
	
	# Output to terminal for simmplicity
	echo "$( curl -ksu ${JSSAdmin}:${JSSPassw} -H "Accept: application/xml" ${JSSURL}/JSSResource/usergroups/id/${noTargetsArray[$i]} | xmllint --xpath '//user_group/name' - | sed -e $'s/\<name\>//g' -e $'s/\<\/name\>/,/g' -e $'s/\,$//' ) (GroupID: ${noTargetsArray[$i]})"
	
	(( i+=1 ))
done

exit 0