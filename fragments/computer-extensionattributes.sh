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
computerextensionattributes_endpoint="$base_url/computerextensionattributes"

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

if [ ! -d "$outputDirectory/XML/computer_extensionattributes" ]; then
	mkdir $outputDirectory/XML/computer_extensionattributes
fi

##########################
# Computer extension_attributes Report #
##########################

# Export all computer extension_attributes
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computerextensionattributes_endpoint" | xmllint --format - > $outputDirectory/XML/computer_extensionattributes.xml

# Create headers for the CSV file
echo "Name,Enabled?,Type,Location" > $outputDirectory/CSV/computer_extensionattributes_$current_date.csv

# Get a list of all computer extension_attribute IDs
extension_attribute_ids=`xmllint --xpath "//computer_extension_attribute/id/text()" $outputDirectory/XML/computer_extensionattributes.xml | tr '\n' ' '`

# Loop through each computer extension_attribute ID
for id in $extension_attribute_ids; do
	computerextensionattribute_endpoint="$computerextensionattributes_endpoint/id/$id"
	extension_attribute_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computerextensionattribute_endpoint"`
	extension_attribute_name=`echo "$extension_attribute_info" | xmllint --xpath "//computer_extension_attribute/name/text()" - | tr "," " " | tr -d "\\/"`
	enabled=`echo "$extension_attribute_info" | xmllint --xpath "//computer_extension_attribute/enabled/text()" -`
	type=`echo "$extension_attribute_info" | xmllint --xpath "//computer_extension_attribute/input_type[platform='Mac']/type/text()" -`
	location=`echo "$extension_attribute_info" | xmllint --xpath "//computer_extension_attribute/inventory_display/text()" -`
	echo "$extension_attribute_name,$enabled,$type,$location" >> $outputDirectory/CSV/computer_extensionattributes_$current_date.csv
	echo $extension_attribute_info | xmllint --format - > "$outputDirectory/XML/computer_extensionattributes/extension_attributeID_$id-$extension_attribute_name.xml"
done