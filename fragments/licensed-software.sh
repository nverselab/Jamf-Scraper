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
licensedsoftwares_endpoint="$base_url/licensedsoftware"

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

if [ ! -d "$outputDirectory/XML/Licensed_Software" ]; then
	mkdir $outputDirectory/XML/Licensed_Software
fi

############################
# Licensed Software Report #
############################

# Export all Licensed Software
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$licensedsoftwares_endpoint" | xmllint --format - > $outputDirectory/XML/licensed_software.xml

# Create headers for the CSV file
echo "Software Name,Publisher,Platform,Count Owned,Violation Email,Remove from Inventory Reports?,Exclude App Store?,Perpetual?,Expiration,Site,Computers,Notes" > $outputDirectory/CSV/licensed_software_$current_date.csv

# Get a list of all licensedsoftware IDs
licensedsoftware_ids=`xmllint --xpath "//licensed_software/id/text()" $outputDirectory/XML/licensed_software.xml | tr '\n' ' '`

# Loop through each licensedsoftware ID
for id in $licensedsoftware_ids; do
	# Make sure $computer_name(s) and $computer_id(s) are blank before starting
	computer_names=""
	computer_name=""
	computer_ids=""
	computer_id=""
	
	licensedsoftware_endpoint="$licensedsoftwares_endpoint/id/$id"
	licensedsoftware_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$licensedsoftware_endpoint"`
	licensedsoftware_name=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/general/name/text()" - | tr "," " " | tr -d "\\/"`
	computer_ids=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/computers/id/text()" - | tr '\n' ' '`
	for computer_id in $computer_ids; do
		computer_name=`echo $(curl -H "Accept: application/xml" -u "$api_username:$api_password" "$base_url/computers/id/$computer_id" | xmllint --xpath "//computer/general/name/text()" -)`
		if [ -z $computer_names ]; then 
			computer_names="$computer_name"
		else
			computer_names="$computer_names;$computer_name"
		fi
	done
	publisher=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/general/publisher/text()" - | tr "," " "`
	email=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/general/send_email_on_violation/text()" -`
	platform=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/general/platform/text()" -`
	removereports=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/general/remove_titles_from_inventory_reports/text()" -`
	appstore=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/general/exclude_titles_purchased_from_app_store/text()" -`
	notes=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/general/notes/text()" - | tr '\n' ";" | tr "," " "`
	expiration=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/licenses/license/purchasing/license_expires/text()" -`
	perpetual=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/licenses/license/purchasing/is_perpetual/text()" -`
	site=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/general/site/name/text()" -`
	count=`echo "$licensedsoftware_info" | xmllint --xpath "//licensed_software/licenses/license/license_count/text()" -`
	echo "$licensedsoftware_name,$publisher,$platform,$count,$email,$removereports,$appstore,$perpetual,$expiration,$site,$computer_names,$notes" >> $outputDirectory/CSV/licensed_software_$current_date.csv
	echo $licensedsoftware_info | xmllint --format - > "$outputDirectory/XML/Licensed_Software/licensedsoftwareID_$id-$licensedsoftware_name.xml"
done
