# This was created to reduce the time tracing a MAC address to a device in the access layer.
# The accuracy is not a hundred percent, as this can be incorrectly reported from the appliance.

$characterFlag
while(!$characterFlag -or $characterFlag -EQ -1) {

    $ciscoMacAddress = Read-Host Enter a Cisco formatted MAC address
    $characterFlag = $ciscoMacAddress.indexof(".")

}

function Format-MacAddress {

    $macAddress = "$ciscoMacAddress"
    $format = $macAddress.split('.')
    $macAddress = $format[0] + $format[1] + $format[2]
    $result = $macAddress -replace '..(?!$)', '$0:'
    return $result

}

$FMA = Format-MacAddress

$json = "application/json"

# ERS Admin credentials
$ersAdminUser = $env:Username
$ersAdminPass = Read-Host Enter Password

# Username and Password Pairing
$upPair = "${ersAdminUser}:${ersAdminPass}"

#Encodes the username and password string into Base64 since ISE requires basic authentication within the request header
$encodedCredentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($upPair))

$RequestHeaders = @{
    'Accept' = "$json"
    'Authorization' = "Basic $encodedCredentials"
    'Content-Type' = "$json"
    
}

$uri = "https://<SERVER-NAME>/dna/system/api/v1/auth/token"

$Response = Invoke-RestMethod -Method Post -Uri $uri -Headers $RequestHeaders
$Token = $Response.Token

function Get-ClientDetail {

    $RequestHeaders = @{
        'Accept' = $json
        'X-Auth-Token' = "$Token"
        'Content-Type' = $json
        
    }

    $uri = "https://SERVER-NAME/dna/intent/api/v1/client-detail?macAddress=$($FMA.ToUpper())"
    $ClientResponse = Invoke-RestMethod -Method Get -Uri $uri -Headers $RequestHeaders -SkipCertificateCheck
    return $ClientResponse.detail


}

$clientInfo = Get-ClientDetail

$clientInfo | Select-Object -Property connectionStatus, hostType, deviceVendor, deviceForm, hostMac, hostIpV4, location, clientConnection, port

Read-Host "Press enter to end execution"
