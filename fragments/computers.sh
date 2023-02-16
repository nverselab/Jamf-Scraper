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
computers_endpoint="$base_url/computers"

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

if [ ! -d "$outputDirectory/XML/Computers" ]; then
	mkdir $outputDirectory/XML/Computers
fi

###################
# Computer Report #
###################

# Export all computers
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computers_endpoint" | xmllint --format - > $outputDirectory/XML/computers.xml

# Create headers for the CSV file
echo "Computer Name,Serial Number,Model,User,Department,Building,Room,OS Version,Enrolled Via DEP,MDM Capable,Last Check-In Time,Site" > $outputDirectory/Reports/computers_$current_date.csv

# Get a list of all computer IDs
computer_ids=`xmllint --xpath "//id/text()" $outputDirectory/XML/computers.xml | tr '\n' ' '`

# Loop through each computer ID
for id in $computer_ids; do
	computer_endpoint="$computers_endpoint/id/$id"
	computer_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computer_endpoint"`
	computer_name=`echo "$computer_info" | xmllint --xpath "//computer/general/name/text()" -`
	serial_number=`echo "$computer_info" | xmllint --xpath "//computer/general/serial_number/text()" -`
	user=`echo "$computer_info" | xmllint --xpath "//computer/location/username/text()" -`
	building=`echo "$computer_info" | xmllint --xpath "//computer/location/building/text()" -`
	room=`echo "$computer_info" | xmllint --xpath "//computer/location/room/text()" -`
	department=`echo "$computer_info" | xmllint --xpath "//computer/location/department/text()" -`
	site=`echo "$computer_info" | xmllint --xpath "//computer/general/site/name/text()" -`
	checkin_time=`echo "$computer_info" | xmllint --xpath "//computer/general/last_contact_time/text()" -`
	enrolled_via_dep=`echo "$computer_info" | xmllint --xpath "//computer/general/management_status/enrolled_via_dep/text()" -`
	mdm_capable=`echo "$computer_info" | xmllint --xpath "//computer/general/mdm_capable/text()" -`
	os_version=`echo "$computer_info" | xmllint --xpath "//computer/hardware/os_version/text()" -`
	model=`echo "$computer_info" | xmllint --xpath "//computer/hardware/model/text()" - | tr "," " "` 
	echo "$computer_name,$serial_number,$model,$user,$department,$building,$room,$os_version,$enrolled_via_dep,$mdm_capable,$checkin_time,$site" >> $outputDirectory/Reports/computers_$current_date.csv
	echo $computer_info | xmllint --format - > $outputDirectory/XML/Computers/computerID_$id-SN_$serial_number.xml
done
