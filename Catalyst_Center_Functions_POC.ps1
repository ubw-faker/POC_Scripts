# JSON Data type
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



function Get-DeviceList {
    
    $RequestHeaders = @{
        'Accept' = $json
        'X-Auth-Token' = "$Token"
        'Content-Type' = $json
        
    }
    
    $uri = "https://<SERVER-NAME>/dna/intent/api/v1/network-device"

    $Response1 = Invoke-RestMethod -Method Get -Uri $uri -Headers $RequestHeaders
    return $Response1.response

}



function Get-DeviceArchive{

    $RequestHeaders = @{
        'Accept' = "$json"
        'X-Auth-Token' = "$Token"
        'Content-Type' = "$json"
        
    }

    $RequestBody = @{

        'deviceId' = @("<DEVICE_ID>")
        'password' = "<PASSWORD>"
    }
    $RequestBody = $RequestBody | Convertto-Json

    $uri1 = "https://<SERVER-NAME>/dna/intent/api/v1/network-device-archive/cleartext"


    $Response1 = Invoke-RestMethod -Method Post -Uri $uri1 -Headers $RequestHeaders -Body $RequestBody
    $url = $Response1.response.url
    $responseUri = "https://<SERVER-NAME>/dna/intent$url"
    $taskResponse = Invoke-RestMethod -Method Get -Uri $responseUri -Headers $RequestHeaders # Run again until additionalStatusUrl is present

    # Create code for recursive job to invoke API until method is present

    $additionalStatusUrl = $taskResponse.response.additionalStatusUrl
    $additionalTaskUri = "https://<SERVER-NAME>/dna/intent$additionalStatusUrl"
    #$additonaltaskResponse = 
    Invoke-RestMethod -Method Get -Uri $additionalTaskUri -Headers $RequestHeaders -OutFile Test.zip # Possible memory limit so OutFile is needed.

}



function Get-DeviceConfigFile {
    
    $RequestHeaders = @{
        'Accept' = $json
        'X-Auth-Token' = "$Token"
        'Content-Type' = $json
        
    }
    
    $uri = "https://<SERVER-NAME>/dna/intent/api/v1/network-device/<DEVICE_ID>/config"

    $Response1 = Invoke-RestMethod -Method Get -Uri $uri -Headers $RequestHeaders
    return $Response1.response

}

function Get-ConfigArchiveDetail {
    
    $RequestHeaders = @{
        'Accept' = $json
        'X-Auth-Token' = "$Token"
        'Content-Type' = $json
        
    }
    
    $uri = "https://<SERVER-NAME>/dna/intent/api/v1/network-device-config"

    $Response1 = Invoke-RestMethod -Method Get -Uri $uri -Headers $RequestHeaders
    return $Response1

}
$ConfDetail = Get-ConfigArchiveDetail
