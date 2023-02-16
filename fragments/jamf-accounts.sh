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
accounts_endpoint="$base_url/accounts"

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

if [ ! -d "$outputDirectory/XML/Access_Accounts" ]; then
	mkdir $outputDirectory/XML/Access_Accounts
fi

if [ ! -d "$outputDirectory/XML/Access_Groups" ]; then
	mkdir $outputDirectory/XML/Access_Groups
fi

########################
# Jamf Accounts Report #
########################

# Export all accounts
curl -H "Accept: application/xml" -u "$api_username:$api_password" "$accounts_endpoint" | xmllint --format - > $outputDirectory/XML/jamf_access_accounts.xml

# Create headers for the CSV file
echo "Username,Full Name,Email Address,Status,Access Level,Directory User,Privilege Set" > $outputDirectory/Reports/jamf_access_accounts_$current_date.csv

# Get a list of all account IDs
account_ids=`xmllint --xpath "//user/id/text()" $outputDirectory/XML/jamf_access_accounts.xml | tr '\n' ' '`

# Loop through each account ID
for id in $account_ids; do
	account_endpoint="$accounts_endpoint/userid/$id"
	account_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$account_endpoint"`
	account_name=`echo "$account_info" | xmllint --xpath "//account/name/text()" -`
	account_fullname=`echo "$account_info" | xmllint --xpath "//account/full_name/text()" -`
	account_email=`echo "$account_info" | xmllint --xpath "//account/email_address/text()" -`
	status=`echo "$account_info" | xmllint --xpath "//account/enabled/text()" -`
	access=`echo "$account_info" | xmllint --xpath "//account/access_level/text()" -`
	directory=`echo "$account_info" | xmllint --xpath "//account/directory_user/text()" -`
	privilege_set=`echo "$account_info" | xmllint --xpath "//account/privilege_set/text()" -`
	echo "$account_name,$account_fullname,$account_email,$status,$access,$directory,$privilege_set" >> $outputDirectory/Reports/jamf_access_accounts_$current_date.csv
	echo $account_info | xmllint --format - > "$outputDirectory/XML/Access_Accounts/AccountID_$id-$account_name.xml"
done

######################
# Jamf Groups Report #
######################

# Get a list of all group IDs
group_ids=`xmllint --xpath "//group/id/text()" $outputDirectory/XML/jamf_access_accounts.xml | tr '\n' ' '`

# Create headers for the CSV file
echo "Group,Access Level,LDAP Server,Privilege Set" > $outputDirectory/Reports/jamf_access_groups_$current_date.csv

# Loop through each group ID
for id in $group_ids; do
	group_endpoint="$accounts_endpoint/groupid/$id"
	group_info=`curl -H "Accept: application/xml" -u "$api_username:$api_password" "$group_endpoint"`
	group_name=`echo "$group_info" | xmllint --xpath "//group/name/text()" -`
	access=`echo "$group_info" | xmllint --xpath "//group/access_level/text()" -`
	ldap_server=`echo "$group_info" | xmllint --xpath "//group/ldap_server/name/text()" -`
	privilege_set=`echo "$group_info" | xmllint --xpath "//group/privilege_set/text()" -`
	echo "$group_name,$access,$ldap_server,$privilege_set" >> $outputDirectory/Reports/jamf_access_groups_$current_date.csv
	echo $group_info | xmllint --format - > "$outputDirectory/XML/Access_Groups/GroupID_$id-$group_name.xml"
done
