# Description

The purpose of this script is to create a custom report of inventory data from Jamf Pro for
reporting, auditing, or archiving records as they exist at runtime.  Inventory object data is pulled
with the Jamf Pro API, formatted, and stored in the XML folder in the directory where the script was run.
Specific values are currated into summary CSV tables for general review in the Reports folder.

This script requires an account in Jamf Pro with Auditor or equivalent permissions. This script
as written will not modify anything in Jamf Pro, but it is always best to use purpose built API accounts
as a precautionary measure.  It is NOT recommended to use any account with Create, Update, or Delete
permissions.

This scrip will make an API call for each object ID it finds.  In large environments this may result
in hundreds or thousands of calls and will take a long time to complete.  Please be patient.

# Instructions

Download the latest version zip file and extract.  Before runninng, make sure to change the base_url to 
your Jamf Pro server, change the credentials for your auditor API account, set an output directory (it
will default to your Desktop folder), and uncomment the lines at the bottom which correspond to the reports
you want to run.
