<# 

The purpose of this script is to test LDAP service account connectivity in ISE, and was written to be understood by non scripters/programmers.
If this script is not functional you will need to access the GUI in ISE.
Once in ISE, nativgate to Administration > Identity Management > External Identity Sources > LDAP,
then click the Test Bind Server button.

API Documentation for structuring requests can be found at https://developer.cisco.com/docs/identity-services-engine/latest/cisco-ise-api-framework
With any details not listed in the API reference documentation, it is best to view the 'Legacy Documents for ERS API' for clarification.

Powershell Documentation for writing API requests can be found at https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod?view=powershell-7.5
PowerShell 7.5 was used to write this script, so any update to PowerShell may change script behavior.

ERS Admin Required to run.

#>

# JSON Data type
$json = "application/json"

# Service Account IDs - If more are created, they can be added here. You will need to do a RESTful request to
# https://<server-domain>:443/ers/config/ldap/ for new IDs (Or whatever the PAN is).
$serviceID = @(
    '<Service-IDs (list)>'      

)

# Corresponding Service name for each ID
$serviceName = @(
    '<service-name>'  

)


# ERS Admin credentials
$ersAdminUser = Read-Host Enter Username
$ersAdminPass = Read-Host Enter Password

# Username and Password Pairing
$upPair = "${ersAdminUser}:${ersAdminPass}"

#Encodes the username and password string into Base64 since ISE requires basic authentication within the request header
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($upPair))

# Content-Type header can be added to this hash table in place of the parameter, but is added during invoke
$requestHeaders = @{
    'Accept' = "$json"
    'Authorization' = "Basic $encodedCredentials"
    
}


# Used for iterating through each service name during the for each loop
$counter = 0


# For each ID within the serviceID array variable the following will execute.
foreach ($ID in $serviceID) {

    # Primary Server API URL/URI for each request. ID array is iterated through to generate a URI for each ID.
    $uri = "https://<server-domain>:443/ers/config/ldap/$ID/testbindprimary"

    # Primary API Call
    $primaryResponse = Invoke-RestMethod -Method Put -ContentType $json -Uri $uri -Headers $requestHeaders -SkipCertificateCheck
    
    # Echoes Service Account
    Write-Host Primary $serviceName[$counter]

    # Primary API Response
    $primaryResponse.OperationResult.resultValue.value

    # Secondary Server API URL/URI for each request. ID array is iterated through to generate a URI for each ID.
    $uri = "https://<server-domain>:443/ers/config/ldap/$ID/testbindsecondary"
    
    # Secondary API Call
    $secondaryResponse = Invoke-RestMethod -Method Put -ContentType $json -Uri $uri -Headers $requestHeaders -SkipCertificateCheck
    
    # Echoes Service Account
    Write-Host Secondary $serviceName[$counter]; $counter++ 

    # Secondary API Response
    $secondaryResponse.OperationResult.resultValue.value
    
	# Newline
    Write-Host 

}


# Clears variable after execution to prevent credential theft
Clear-Variable -Name ersAdminUser, ersAdminPass, upPair, encodedCredentials, counter
