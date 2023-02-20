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
devices_endpoint="$base_url/mobiledevices"

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

if [ ! -d "$outputDirectory/XML/Devices" ]; then
	mkdir $outputDirectory/XML/Devices
fi

#################
# Device Report #
#################

# Export all devices
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$devices_endpoint" | xmllint --format - > $outputDirectory/XML/devices.xml

# Create headers for the CSV file
echo "Device Name,Serial Number,Model,User,Department,Building,Room,OS Version,Enrollment Method,Supervised,Last Inventory Update,Site,Group Memberships" > $outputDirectory/Reports/devices_$current_date.csv

# Get a list of all device IDs
device_ids=`xmllint --xpath "//mobile_device/id/text()" $outputDirectory/XML/devices.xml | tr '\n' ' '`

# Loop through each device ID
for id in $device_ids; do
	device_endpoint="$devices_endpoint/id/$id"
	device_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$device_endpoint"`
	device_name=`echo "$device_info" | xmllint --xpath "//mobile_device/general/name/text()" -`
	serial_number=`echo "$device_info" | xmllint --xpath "//mobile_device/general/serial_number/text()" -`
	user=`echo "$device_info" | xmllint --xpath "//mobile_device/location/username/text()" -`
	building=`echo "$device_info" | xmllint --xpath "//mobile_device/location/building/text()" -`
	room=`echo "$device_info" | xmllint --xpath "//mobile_device/location/room/text()" -`
	department=`echo "$device_info" | xmllint --xpath "//mobile_device/location/department/text()" -`
	site=`echo "$device_info" | xmllint --xpath "//mobile_device/general/site/name/text()" -`
	inventory_time=`echo "$device_info" | xmllint --xpath "//mobile_device/general/last_inventory_update/text()" - | tr "," " "`
	enrollement_method=`echo "$device_info" | xmllint --xpath "//mobile_device//general/enrollment_method/text()" -`
	supervised=`echo "$device_info" | xmllint --xpath "//mobile_device/general/supervised/text()" -`
	os_version=`echo "$device_info" | xmllint --xpath "//mobile_device/general/os_version/text()" -`
	model=`echo "$device_info" | xmllint --xpath "//mobile_device/general/model/text()" - | tr "," " "` 
	device_groups=`echo "$device_info" | xmllint --xpath "//mobile_device/mobile_device_groups/mobile_device_group/name/text()" - | tr '\n' ";" | tr "," " "`
	echo "$device_name,$serial_number,$model,$user,$department,$building,$room,$os_version,$enrollement_method,$supervised,$inventory_time,$site,$device_groups" >> $outputDirectory/Reports/devices_$current_date.csv
	echo $device_info | xmllint --format - > "$outputDirectory/XML/Devices/deviceID_$id-SN_$serial_number.xml"
done