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
scripts_endpoint="$base_url/scripts"

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

if [ ! -d "$outputDirectory/XML/scripts" ]; then
	mkdir $outputDirectory/XML/scripts
fi

##########################
# Computer scripts Report #
##########################

# Export all computer scripts
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$scripts_endpoint" | xmllint --format - > $outputDirectory/XML/scripts.xml

# Create headers for the CSV file
echo "Name,Category,Filename,Priority,Info,Notes" > $outputDirectory/CSV/scripts_$current_date.csv

# Get a list of all computer script IDs
script_ids=`xmllint --xpath "//script/id/text()" $outputDirectory/XML/scripts.xml | tr '\n' ' '`

# Loop through each computer group ID
for id in $script_ids; do
	script_endpoint="$scripts_endpoint/id/$id"
	script_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$script_endpoint"`
	script_name=`echo "$script_info" | xmllint --xpath "//script/name/text()" - | tr "," " " | tr -d "\\/"`
	category=`echo "$script_info" | xmllint --xpath "//script/category/text()" -`
	filename=`echo "$script_info" | xmllint --xpath "//script/filename/text()" - | tr "," " " | tr ";" " "`
	priority=`echo "$script_info" | xmllint --xpath "//script/priority/text()" -`
	info=`echo "$script_info" | xmllint --xpath "//script/info/text()" - | tr "," " " | tr ";" " "`
	notes=`echo "$script_info" | xmllint --xpath "//script/notes/text()" - | tr "," " " | tr ";" " "`
	echo "$script_name,$category,$filename,$priority,$info,$notes" >> $outputDirectory/CSV/scripts_$current_date.csv
	echo $script_info | xmllint --format - > "$outputDirectory/XML/scripts/scriptID_$id-$script_name.xml"
done