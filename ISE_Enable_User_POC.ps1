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

$Body = @{
    InternalUser = @{
        name =  "<username>"
        enabled =  "true"
    }
}

# Converts request body to JSON since the hash table is nested and causes errors due to the object being presented instead of the data.
$RequestBody = $Body | ConvertTo-Json

$uri1 = "https://<server-name>:443/ers/config/internaluser/<user-ID>"


$Response1 = Invoke-RestMethod -Method Put -ContentType $json -Uri $uri1 -Headers $RequestHeaders -Body $RequestBody

$Response1.UpdatedFieldsList.updatedField

Clear-Variable ersAdminPass, ersAdminUser, encodedCredentials

 
