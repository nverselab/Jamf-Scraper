#!/bin/bash

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
deviceprofiles_endpoint="$base_url/mobiledeviceconfigurationprofiles"

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

if [ ! -d "$outputDirectory/XML/device_profiles" ]; then
	mkdir $outputDirectory/XML/device_profiles
fi

###################
# device_profiles Report #
###################

# Export all device_profiles
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$deviceprofiles_endpoint" | xmllint --format - > $outputDirectory/XML/device_profiles.xml

# Create headers for the CSV file
echo "Profile Name,Category,Install Level,Deployment Method,Site,All Devices?,Devices,Device Groups,All Users?,Users,User Groups,Buildings,Departments" > $outputDirectory/CSV/device_profiles_$current_date.csv

# Get a list of all device_profile IDs
deviceprofile_ids=`xmllint --xpath "//configuration_profile/id/text()" $outputDirectory/XML/device_profiles.xml | tr '\n' ' '`

# Loop through each deviceprofile ID
for id in $deviceprofile_ids; do
	deviceprofile_endpoint="$deviceprofiles_endpoint/id/$id"
	deviceprofile_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$deviceprofile_endpoint"`
	deviceprofile_name=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/general/name/text()" - | tr "," " " | tr -d "\\/"`
	category=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/general/category/name/text()" -`
	site=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/general/site/name/text()" -`
	level=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/general/level/text()" -`
	deployment_method=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/general/deployment_method/text()" -`
	all_devices=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/scope/all_mobile_devices/text()" -`
	all_users=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/scope/all_jss_users/text()" -`
	devices=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/scope/mobile_devices/mobile_device/name/text()" - | tr '\n' ';'`
	device_groups=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/scope/mobile_device_groups/mobile_device_group/name/text()" - | tr '\n' ";" | tr "," " "`
	users=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/scope/jss_users/user/name/text()" - | tr '\n' ';'`
	user_groups=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/scope/jss_user_groups/user_group/name/text()" - | tr '\n' ";" | tr "," " "`
	buildings=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/scope/buildings/building/name/text()" - | tr '\n' ";" | tr "," " "`
	departments=`echo "$deviceprofile_info" | xmllint --xpath "//configuration_profile/scope/departments/department/name/text()" - | tr '\n' ";" | tr "," " "`
	echo "$deviceprofile_name,$category,$level,$deployment_method,$site,$all_devices,$devices,$device_groups,$all_users,$users,$user_groups,$buildings,$departments" >> $outputDirectory/CSV/device_profiles_$current_date.csv
	echo $deviceprofile_info | xmllint --format - > "$outputDirectory/XML/device_profiles/deviceprofileID_$id-$deviceprofile_name.xml"
done
