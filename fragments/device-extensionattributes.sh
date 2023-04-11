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
deviceextensionattributes_endpoint="$base_url/mobiledeviceextensionattributes"

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

if [ ! -d "$outputDirectory/XML/device_extensionattributes" ]; then
	mkdir $outputDirectory/XML/device_extensionattributes
fi

##########################
# device extension_attributes Report #
##########################

# Export all device extension_attributes
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$deviceextensionattributes_endpoint" | xmllint --format - > $outputDirectory/XML/device_extensionattributes.xml

# Create headers for the CSV file
echo "Name,Type,Mapping,Location" > $outputDirectory/CSV/device_extensionattributes_$current_date.csv

# Get a list of all device extension_attribute IDs
extension_attribute_ids=`xmllint --xpath "//mobile_device_extension_attribute/id/text()" $outputDirectory/XML/device_extensionattributes.xml | tr '\n' ' '`

# Loop through each device extension_attribute ID
for id in $extension_attribute_ids; do
	deviceextensionattribute_endpoint="$deviceextensionattributes_endpoint/id/$id"
	extension_attribute_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$deviceextensionattribute_endpoint"`
	extension_attribute_name=`echo "$extension_attribute_info" | xmllint --xpath "//mobile_device_extension_attribute/name/text()" - | tr "," " " | tr -d "\\/"`
	type=`echo "$extension_attribute_info" | xmllint --xpath "//mobile_device_extension_attribute/input_type/type/text()" -`
	mapping=`echo "$extension_attribute_info" | xmllint --xpath "//mobile_device_extension_attribute/input_type/attribute_mapping/text()" -`
	location=`echo "$extension_attribute_info" | xmllint --xpath "//mobile_device_extension_attribute/inventory_display/text()" -`
	echo "$extension_attribute_name,$type,$mapping,$location" >> $outputDirectory/CSV/device_extensionattributes_$current_date.csv
	echo $extension_attribute_info | xmllint --format - > "$outputDirectory/XML/device_extensionattributes/extension_attributeID_$id-$extension_attribute_name.xml"
done