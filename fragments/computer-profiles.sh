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
computerprofiles_endpoint="$base_url/osxconfigurationprofiles"

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

if [ ! -d "$outputDirectory/XML/computer_profiles" ]; then
	mkdir $outputDirectory/XML/computer_profiles
fi

###################
# computer_profiles Report #
###################

# Export all computer_profiles
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computerprofiles_endpoint" | xmllint --format - > $outputDirectory/XML/computer_profiles.xml

# Create headers for the CSV file
echo "Profile Name,Category,Install Level,Distribution Method,Site,All Computers?,Computers,Computer Groups,All Users?,Users,User Groups,Buildings,Departments" > $outputDirectory/CSV/computer_profiles_$current_date.csv

# Get a list of all computer_profile IDs
computerprofile_ids=`xmllint --xpath "//os_x_configuration_profile/id/text()" $outputDirectory/XML/computer_profiles.xml | tr '\n' ' '`

# Loop through each computerprofile ID
for id in $computerprofile_ids; do
	computerprofile_endpoint="$computerprofiles_endpoint/id/$id"
	computerprofile_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$computerprofile_endpoint"`
	computerprofile_name=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/general/name/text()" - | tr "," " " | tr -d "\\/"`
	category=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/general/category/name/text()" -`
	site=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/general/site/name/text()" -`
	level=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/general/level/text()" -`
	distribution_method=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/general/distribution_method/text()" -`
	all_computers=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/scope/all_computers/text()" -`
	all_users=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/scope/all_jss_users/text()" -`
	computers=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/scope/computers/computer/name/text()" - | tr '\n' ';'`
	computer_groups=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/scope/computer_groups/computer_group/name/text()" - | tr '\n' ";" | tr "," " "`
	users=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/scope/jss_users/user/name/text()" - | tr '\n' ';'`
	user_groups=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/scope/jss_user_groups/user_group/name/text()" - | tr '\n' ";" | tr "," " "`
	buildings=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/scope/buildings/building/name/text()" - | tr '\n' ";" | tr "," " "`
	departments=`echo "$computerprofile_info" | xmllint --xpath "//os_x_configuration_profile/scope/departments/department/name/text()" - | tr '\n' ";" | tr "," " "`
	echo "$computerprofile_name,$category,$level,$distribution_method,$site,$all_computers,$computers,$computer_groups,$all_users,$users,$user_groups,$buildings,$departments" >> $outputDirectory/CSV/computer_profiles_$current_date.csv
	echo $computerprofile_info | xmllint --format - > "$outputDirectory/XML/computer_profiles/computerprofileID_$id-$computerprofile_name.xml"
done
