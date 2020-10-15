# Get-VasttrafikBus
Gets information about bus timetables from Västtrafiks API.
User need to specify a authorization key from https://developer.vasttrafik.se/ and add it under "$AuthToken" variable.
Replace "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" with correct Authorization.

How to find the correct authorization:
1. Create a account at: https://developer.vasttrafik.se/
2. Create a project and subscribe to: https://developer.vasttrafik.se/portal/#/api/Reseplaneraren/v2/landerss
3. Go to "My Applications" and find your application/project then click "Manage keys"
4. Find "Curl command for client credential grant" and replace "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" in the .ps1 file with the key.

I am new to PowerShell, this is my fourth function, keep it in mind! 
