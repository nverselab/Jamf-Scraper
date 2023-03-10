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
computergroups_endpoint="$base_url/computergroups"

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

if [ ! -d "$outputDirectory/XML/Computer_Groups" ]; then
	mkdir $outputDirectory/XML/Computer_Groups
fi

##########################
# Computer Groups Report #
##########################

# Export all computer groups
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computergroups_endpoint" | xmllint --format - > $outputDirectory/XML/computer_groups.xml

# Create headers for the CSV file
echo "Group Name,Smart Group,Count,Site" > $outputDirectory/CSV/computer_groups_$current_date.csv

# Get a list of all computer group IDs
group_ids=`xmllint --xpath "//computer_group/id/text()" $outputDirectory/XML/computer_groups.xml | tr '\n' ' '`

# Loop through each computer group ID
for id in $group_ids; do
	computergroup_endpoint="$computergroups_endpoint/id/$id"
	group_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computergroup_endpoint"`
	group_name=`echo "$group_info" | xmllint --xpath "//computer_group/name/text()" - | tr "," " " | tr -d "\\/"`
	smart=`echo "$group_info" | xmllint --xpath "//computer_group/is_smart/text()" -`
	count=`echo "$group_info" | xmllint --xpath "//computer_group/computers/size/text()" -`
	site=`echo "$group_info" | xmllint --xpath "//computer_group/site/name/text()" -`
	echo "$group_name,$smart,$count,$site" >> $outputDirectory/CSV/computer_groups_$current_date.csv
	echo $group_info | xmllint --format - > "$outputDirectory/XML/Computer_Groups/groupID_$id-$group_name.xml"
done