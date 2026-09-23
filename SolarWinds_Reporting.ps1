Set-Location "<PATH_TO_OUTPUT_FOLDER>"

function Import-Credentials {
    
    # Domain credentials to run
    $DomainPassword = ConvertTo-SecureString -String $(Get-Content <PATH_TO_PASSWORD> -ErrorAction Stop) -Key $(Get-Content <PATH_TO_KEY> -ErrorAction Stop) #| ConvertFrom-SecureString -AsPlainText -ErrorAction Stop

    return $DomainPassword

}


$ServiceAccount = "<USERNAME>"
$Secret = Import-Credentials

$Credential = New-Object System.Management.Automation.PSCredential($ServiceAccount, $Secret)

$swisCred = $Credential 

$swisConnection = Connect-Swis -Credential $swisCred -Hostname <POLLER_HOSTNAME>

function Get-RemoteLatency {

    $instanceList = @(
        '<NODE_ID_LIST>'
    
    )

    $siteList = @(
        '<SITE_NAME>'

    )

    # An empty object/array to be filled with all query results
    $objectList = New-Object 'System.Collections.Generic.List[object]'

    foreach ($instance in $instanceList) {

    $SwqlQuery = "SELECT DISTINCT TOP 1 OperationInstanceID, OperationName, OperationTypeID, RecordTime, AvgRoundTripTime, SourceNodeID
    FROM Orion.IpSla.JitterOperationResults 
    WHERE OperationTypeID = 11 AND OperationInstanceID = $instance AND OperationName IS NOT NULL ORDER BY RecordTime DESC"


    $response = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery
    $objectList.Add([PSCustomObject]$response)

    } 


    foreach ($site in $siteList) {

       Write-Host "$site Round Trip Average"
       [Math]::Round((($objectList | Where-Object -Property OperationName -like "$site*").AvgRoundTripTime | Measure-Object -Average).Average)
       Write-Host

       $SiteAverage = [Math]::Round((($objectList | Where-Object -Property OperationName -like "$site*").AvgRoundTripTime | Measure-Object -Average).Average)
       
       "$site, $SiteAverage, $((Get-Date -Format "MM-dd-yyyy h:mm:sstt").ToString())" | Out-File "<PATH_TO_CSV>" -Append

    }



    

}


function Get-VPNCount {

    $nodeList = @(

        '<NODE_ID>'
    
    )

    # An empty object/array to be filled with all query results
    $objectList = New-Object 'System.Collections.Generic.List[object]'
    $counter = 0

    foreach ($node in $nodeList) {

        $SwqlQuery = "SELECT AssignmentName, CustomPollerAssignmentID, NodeID, CustomPollerOid, CurrentValue, ID, CustomPollerMIB, StatusDescription
        FROM Orion.NPM.CustomPollerAssignment WHERE CustomPollerID = '<CUSTOM_POLLER_ID>' AND StatusDescription = 'Up' AND NodeID = $node"


        $response = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery
    

        $objectList.Add([PSCustomObject]$response)

        $PollerAssignmentID = $objectList[$counter].CustomPollerAssignmentID.Guid

        $subSwqlQuery = "SELECT MAX(Status) AS Daily_Max
        #FROM Orion.NPM.CustomPollerStatistics WHERE CustomPollerAssignmentID = '$PollerAssignmentID'
        #AND DATETIME >= ADDDATE('hour', -24, GETDATE())"

        $subQueryResponse = Get-SwisData -SwisConnection $SwisConnection -Query $subSwqlQuery

        $LOB #Initialized Variable

        switch ($counter) {

            0 {Write-Host "Medicare VPN"; Write-Host "----------------"; $LOB = "Medicare"; break}
            2 {Write-Host "Corporate VPN"; Write-Host "----------------"; $LOB = "Corporate"; break}
            4 {Write-Host "Tricare VPN"; Write-Host "----------------"; $LOB = "Tricare"; break}
            default {break}

    }

    $Device =  $objectList[$counter].AssignmentName -split 'crasNumSessions on '

    Write-Host "Device:$Device"
    Write-Host "Current Value: " -NoNewline
    $objectList[$counter].CurrentValue
    Write-Host "24 Hour Max: $subQueryResponse"
    Write-Host
    "$Device, $($objectList[$counter].CurrentValue), $subQueryResponse, $LOB,$((Get-Date -Format "MM-dd-yyyy h:mm:sstt").ToString())" |`
    Out-File "<PATH_TO_CSV>" -Append

    $counter++

    }


}


function Get-CubeStatus {

    Remove-Item "<PATH_TO_PREVIOUS_CSV>" -ErrorAction SilentlyContinue

    $NodeID = @(
        '<NODE_ID_LIST>'
    )

    $interfaceID = @(
        '<INTERFACE_ID_LIST>'
    )

    # An empty object/array to be filled with all query results
    $objectList = New-Object 'System.Collections.Generic.List[object]'

    foreach ($Interface in $InterfaceID) {

        $SwqlQuery = "SELECT TOP 1000 NodeID, InterfaceID, AdminStatus, OperStatus, FullName, Outbps, Inbps, Bps, MaxInBpsToday, MaxInBpsTime, MaxOutBpsToday, InterfaceLastChange, Status, InterfaceResponding
        FROM Orion.NPM.Interfaces
        WHERE InterfaceID = $Interface"


        $response = Get-SwisData -SwisConnection $SwisConnection -Query $SwqlQuery
        $objectList.Add([PSCustomObject]$response)

    } 


    foreach ($Node in $NodeID) {
        $limit = (($objectList | Where-Object -Property NodeID -EQ $Node) | Measure-Object).Count
        for($count = 0; $count -le $limit; $count++) {
    
        if($count -eq $limit) {
    
            break;
        }
        ($objectList | Where-Object -Property NodeID -EQ $Node)[$count].FullName
        Write-Host
        if((($objectList | Where-Object -Property NodeID -EQ $Node)[$count].Status) -eq 1){
            Write-Host Up
            Write-Host 
            "$(($objectList | Where-Object -Property NodeID -EQ $Node)[$count].FullName), Up, $((Get-Date -Format "MM-dd-yyyy h:mm:sstt").ToString())" | Out-File "<PATH_TO_CSV>" -Append

        } else {
            Write-Host Down; Write-Host
            "$(($objectList | Where-Object -Property NodeID -EQ $Node)[$count].FullName), Down, $((Get-Date -Format "MM-dd-yyyy h:mm:sstt").ToString())" | Out-File "<PATH_TO_CSV>" -Append
        }

        }
    }

}

cls

Get-RemoteLatency;
Get-VPNCount;
Get-CubeStatus


<#
Working test query

$SwqlQuery = "SELECT DISTINCT TOP 1 OperationInstanceID, OperationName, OperationTypeID, RecordTime, AvgRoundTripTime
FROM Orion.IpSla.JitterOperationResults 
WHERE OperationInstanceID = 949 AND OperationName IS NOT NULL ORDER BY RecordTime DESC"
#>
