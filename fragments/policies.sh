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
policies_endpoint="$base_url/policies"

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

if [ ! -d "$outputDirectory/XML/Policies" ]; then
	mkdir $outputDirectory/XML/Policies
fi

###################
# Policies Report #
###################

# Export all policies
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$policies_endpoint" | xmllint --format - > $outputDirectory/XML/policies.xml

# Create headers for the CSV file
echo "Policy Name,Enabled?,Check-in?,Enroll Complete?,Login?,Startup?,Netstate Change?,EventID,Offline?,Category,Self Service?,Site,All Computers?,Computers,Computer Groups,Buildings,Departments" > $outputDirectory/CSV/policies_$current_date.csv

# Get a list of all policy IDs
policy_ids=`xmllint --xpath "//policy/id/text()" $outputDirectory/XML/policies.xml | tr '\n' ' '`

# Loop through each policy ID
for id in $policy_ids; do
	policy_endpoint="$policies_endpoint/id/$id"
	policy_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$policy_endpoint"`
	policy_name=`echo "$policy_info" | xmllint --xpath "//policy/general/name/text()" - | tr "," " " | tr -d "\\/"`
	enabled=`echo "$policy_info" | xmllint --xpath "//policy/general/enabled/text()" -`
	checkin=`echo "$policy_info" | xmllint --xpath "//policy/general/trigger_checkin/text()" -`
	enrollment=`echo "$policy_info" | xmllint --xpath "//policy/general/trigger_enrollment_complete/text()" -`
	login=`echo "$policy_info" | xmllint --xpath "//policy/general/trigger_login/text()" -`
	netstate=`echo "$policy_info" | xmllint --xpath "//policy/general/trigger_network_state_changed/text()" -`
	startup=`echo "$policy_info" | xmllint --xpath "//policy/general/trigger_startup/text()" -`
	event=`echo "$policy_info" | xmllint --xpath "//policy/general/trigger_other/text()" -`
	offline=`echo "$policy_info" | xmllint --xpath "//policy/general/offline/text()" -`
	category=`echo "$policy_info" | xmllint --xpath "//policy/general/category/name/text()" -`
	site=`echo "$policy_info" | xmllint --xpath "//policy/general/site/name/text()" -`
	all_computers=`echo "$policy_info" | xmllint --xpath "//policy/scope/all_computers/text()" -`
	computers=`echo "$policy_info" | xmllint --xpath "//policy/scope/computers/computer/name/text()" - | tr '\n' ';'`
	computer_groups=`echo "$policy_info" | xmllint --xpath "//policy/scope/computer_groups/computer_group/name/text()" - | tr '\n' ";" | tr "," " "`
	buildings=`echo "$policy_info" | xmllint --xpath "//policy/scope/buildings/building/name/text()" - | tr '\n' ";" | tr "," " "`
	departments=`echo "$policy_info" | xmllint --xpath "//policy/scope/departments/department/name/text()" - | tr '\n' ";" | tr "," " "`
	selfservice=`echo "$policy_info" | xmllint --xpath "//policy/self_service/use_for_self_service/text()" -`
	echo "$policy_name,$enabled,$checkin,$enrollment,$login,$startup,$netstate,$event,$offline,$category,$selfservice,$site,$all_computers,$computers,$computer_groups,$buildings,$departments" >> $outputDirectory/CSV/policies_$current_date.csv
	echo $policy_info | xmllint --format - > "$outputDirectory/XML/Policies/policyID_$id-$policy_name.xml"
done
