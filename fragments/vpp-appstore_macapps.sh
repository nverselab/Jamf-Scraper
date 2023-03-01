#!/bin/bash

#############
# Variables #
#############

# Base URL for Jamf Pro API endpoint
base_url="$1"

# Jamf Pro API credentials
api_username="$2"
api_password="$3"

# Output Directory Path
outputDirectory="$4"

# Jamf Pro API endpoint URLs
macapplications_endpoint="$base_url/macapplications"

# Get the current date in the format YYYY-MM-DD
current_date=$(date +%Y-%m-%d)

#############################
# Generate Folder Structure #
#############################

# Create the XML and Reports folder if it doesn't exist
if [ ! -d "$outputDirectory" ]; then
	mkdir $outputDirectory
	mkdir $outputDirectory/XML
	mkdir $outputDirectory/CSV
	mkdir $outputDirectory/Reports
fi

if [ ! -d "$outputDirectory/XML/VPP_MacApps" ]; then
	mkdir $outputDirectory/XML/VPP_MacApps
fi

############################
# VPP Software Report #
############################

# Export all VPP Software
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$macapplications_endpoint" | xmllint --format - > $outputDirectory/XML/vpp_macapps.xml

# Create headers for the CSV file
echo "Software Name,Owned,Used,Remaining,Deployment,Device Based?,Bundle ID,AppStore URL,Category,Site,All Computers?,Computers,Computer Groups,All Users?" > $outputDirectory/CSV/vpp_macapps_$current_date.csv

# Get a list of all VPPsoftware IDs
macapplication_ids=`xmllint --xpath "//mac_application/id/text()" $outputDirectory/XML/vpp_macapps.xml | tr '\n' ' '`

# Loop through each VPPsoftware ID
for id in $macapplication_ids; do
	# Make sure $computer_name(s) and $computer_id(s) are blank before starting
	computer_names=""
	computer_name=""
	computer_ids=""
	computer_id=""
	
	macapplication_endpoint="$macapplications_endpoint/id/$id"
	macapplication_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$macapplication_endpoint"`
	macapplication_name=`echo "$macapplication_info" | xmllint --xpath "//mac_application/general/name/text()" - | tr "," " " | tr -d "\\/"`
	computer_ids=`echo "$macapplication_info" | xmllint --xpath "//mac_application/scope/computers/computer/id/text()" - | tr '\n' ' '`
	
	for computer_id in $computer_ids; do
		computer_name=`echo $(curl -H "Accept: application/xml" -u "$api_username:$api_password" "$base_url/computers/id/$computer_id" | xmllint --xpath "//computer/general/name/text()" -)`
		if [ -z $computer_names ]; then 
			computer_names="$computer_name"
		else
			computer_names="$computer_names;$computer_name"
		fi
	done
	bundleid=`echo "$macapplication_info" | xmllint --xpath "//mac_application/general/bundle_id/text()" -`
	owned=`echo "$macapplication_info" | xmllint --xpath "//mac_application/vpp/total_vpp_licenses/text()" -`
	used=`echo "$macapplication_info" | xmllint --xpath "//mac_application/vpp/used_vpp_licenses/text()" -`
	remaining=`echo "$macapplication_info" | xmllint --xpath "//mac_application/vpp/remaining_vpp_licenses/text()" -`
	deployment=`echo "$macapplication_info" | xmllint --xpath "//mac_application/general/deployment_type/text()" - | tr "," " "`
	devicebased=`echo "$macapplication_info" | xmllint --xpath "//mac_application/vpp/assign_vpp_device_based/text()" -`
	site=`echo "$macapplication_info" | xmllint --xpath "//mac_application/general/site/name/text()" -`
	category=`echo "$macapplication_info" | xmllint --xpath "//mac_application/general/category/name/text()" -`
	url=`echo "$macapplication_info" | xmllint --xpath "//mac_application/general/url/text()" -`
	allcomputers=`echo "$macapplication_info" | xmllint --xpath "//mac_application/scope/all_computers/text()" -`
	allusers=`echo "$macapplication_info" | xmllint --xpath "//mac_application/scope/all_jss_users/text()" -`
	computer_groups=`echo "$macapplication_info" | xmllint --xpath "//mac_application/scope/computer_groups/computer_group/name/text()" - | tr '\n' ";" | tr "," " "`
	echo "$macapplication_name,$owned,$used,$remaining,$deployment,$devicebased,$bundleid,$url,$category,$site,$allcomputers,$computer_names,$computer_groups,$allusers" >> $outputDirectory/CSV/vpp_macapps_$current_date.csv
	echo $macapplication_info | xmllint --format - > "$outputDirectory/XML/VPP_MacApps/VPP-AppStore_AppID_$id-$macapplication_name.xml"
done
