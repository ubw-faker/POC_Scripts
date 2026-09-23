
# Change directory to reporting folder. All output from this script will go to this folder.
Set-Location -Path "<PATH-TO-FILE>"

# Domain credentials to run
$DomainPassword = Read-Host "Enter admin password"


# Function to generate token for API call for Panorama
function Get-TokenKey {

    $RequestBody = @{
        'type' = "keygen"
        'user' = "$env:USERNAME"
        'password' = "$DomainPassword"

    
    }

    $uri = "https://<SERVER-NAME>/api/"

    $TokenResponse = Invoke-RestMethod -Method Post -ContentType application/x-www-form-urlencoded -Uri $uri -Body $RequestBody

    $response = $TokenResponse.response.result.key

    return $response

}

# Function for API call for Panorama device summary
function Get-PANDevices {

    $AllDevicesUri = "https://<SERVER-NAME>/api/?type=op&cmd=<show><devices><all></all></devices></show>&key=$key" 
    
    $DeviceResult = Invoke-RestMethod -Uri $AllDevicesUri

    return $DeviceResult


}

function Check-UserIDError {

    $CurrentTime = (Get-Date).ToUniversalTime().ToString("yyyy/MM/dd HH:mm:ss")
    $Last24Hrs = (Get-Date).ToUniversalTime().AddDays(-1).ToString("yyyy/MM/dd HH:mm:ss")
    $testUri = "https://<SERVER-NAME>/api/?type=log&log-type=system&nlogs=5000&query=(description contains 'User-ID Agent Prod') and (eventid eq connect-agent-failure) and ((time_generated leq `'$CurrentTime`') and (time_generated geq `'$Last24Hrs`'))&key=$key"
    if (($PSVersionTable.PSVersion.Major) -EQ 7) {
        $response = Invoke-RestMethod -Uri $testUri -SkipCertificateCheck
    } else {
            $response = Invoke-RestMethod -Uri $testUri
    }
    #Job ID from the query
    Start-Sleep 10
    $JobID = $response.response.result.job
    $jobURI = "https://<SERVER-NAME>/api/?type=log&action=get&job-id=$JobID&key=$key"
    $responseData = Invoke-RestMethod -Uri $jobURI
    $responseData.response.result.log.logs.entry | Select-Object device_name,opaque,time_generated | Export-Csv USER_ID_CHECK.csv -NoTypeInformation -Force

}

##################
#Panorama Section#
##################

# Function Calls
$key = Get-TokenKey
$status = Get-PanDevices

# Formats device summary information
$hostnames = $status.response.result.devices.entry | Where-Object -Property connected -EQ no | Select-Object -Property hostname

# Generates CSV list of hostnames for disconnected devices   
$hostnames | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File PAN_DEV_DISCONNECTED.csv -Force

# Formats device summary information
$State = $status.response.result.devices.entry | Where-Object -Property connected -EQ yes | Select-Object -Property hostname, av-version -ExpandProperty ha -ErrorAction Ignore

# Generates CSV for device summary
$State | Sort-Object -Property hostname | Select-Object -Property hostname, av-version, state -ExcludeProperty peer | Export-Csv PAN_DEV_SUMMARY.csv -NoTypeInformation -Force


# User-ID Check
Check-UserIDError

# Sanitize sensitive information
Clear-Variable -Name DomainPassword, key, status, ngnkey, ngnstatus, hostnames, ngnhostnames, State, ngnState -ErrorAction Ignore
