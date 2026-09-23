# JSON Data type
$json = "application/json"

# ERS Admin credentials
$ersAdminUser = Read-Host Enter Username
$ersAdminPass = Read-Host Enter Password

# Username and Password Pairing
$upPair = "${ersAdminUser}:${ersAdminPass}"

#Encodes the username and password string into Base64 since ISE requires basic authentication within the request header
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($upPair))

# Content-Type header can be added to this hash table in place of the parameter, but is added during invoke.
# Request header requirements https://developer.cisco.com/docs/identity-services-engine/latest/request-heaers/#request-method-types
$RequestHeaders = @{
    'Accept' = "$json"
    'Authorization' = "Basic $encodedCredentials"
    
}


$uri = "https://<SERVER-NAME>:443/ers/config/internaluser/"

$Response = Invoke-RestMethod -Method Get -ContentType $json -Uri $uri -Headers $RequestHeaders

$Response.SearchResult.resources

Clear-Variable ersAdminPass, ersAdminUser, encodedCredentials
