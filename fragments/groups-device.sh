#!/bin/bash

#############
# Variables #
#############

# Base URL for Jamf Pro API endpoint
base_url=$1

# Jamf Pro API credentials
api_username=$2
api_password=$3

# Output Directory Path
outputDirectory=$4

# Jamf Pro API endpoint URLs
devicegroups_endpoint="$base_url/mobiledevicegroups"

# Get the current date in the format YYYY-MM-DD
current_date=$(date +%Y-%m-%d)

#############################
# Generate Folder Structure #
#############################

# Create the XML and Reports folder if it doesn't exist
if [ ! -d "$outputDirectory" ]; then
	mkdir $outputDirectory
	mkdir $outputDirectory/XML
	mkdir $outputDirectory/Reports
fi

if [ ! -d "$outputDirectory/XML/Device_Groups" ]; then
	mkdir $outputDirectory/XML/Device_Groups
fi

########################
# Device Groups Report #
########################

# Export all device groups
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$devicegroups_endpoint" | xmllint --format - > $outputDirectory/XML/device_groups.xml

# Create headers for the CSV file
echo "Group Name,Smart Group,Count,Site" > $outputDirectory/Reports/device_groups_$current_date.csv

# Get a list of all device group IDs
group_ids=`xmllint --xpath "//mobile_device_group/id/text()" $outputDirectory/XML/device_groups.xml | tr '\n' ' '`

# Loop through each computer group ID
for id in $group_ids; do
	devicegroup_endpoint="$devicegroups_endpoint/id/$id"
	group_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$devicegroup_endpoint"`
	group_name=`echo "$group_info" | xmllint --xpath "//mobile_device_group/name/text()" - | tr "," " " | tr -d "\\/"`
	smart=`echo "$group_info" | xmllint --xpath "//mobile_device_group/is_smart/text()" -`
	count=`echo "$group_info" | xmllint --xpath "//mobile_device_group/mobile_devices/size/text()" -`
	site=`echo "$group_info" | xmllint --xpath "//mobile_device_group/site/name/text()" -`
	echo "$group_name,$smart,$count,$site" >> $outputDirectory/Reports/device_groups_$current_date.csv
	echo $group_info | xmllint --format - > "$outputDirectory/XML/Device_Groups/groupID_$id-$group_name.xml"
done