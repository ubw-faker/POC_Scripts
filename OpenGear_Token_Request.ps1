

$DomainPassword = Read-Host Enter MGT Password

$RequestBody = @{
    'username' = "$env:USERNAME"
    'password' = "$DomainPassword"

}

$Body = $RequestBody | Convertto-Json

$uri = "https://<server-name>/api/v1.5/sessions"

$TokenResponse = Invoke-RestMethod -Method Post -ContentType application/json -Uri $uri -Body $Body -SkipCertificateCheck

$Token = "Token $($TokenResponse.session)"

$Headers = @{
    'Accept' = "application/json"
    'Authorization' = $Token
}


$UserUri = "https://<server-name>/api/v1.5/users"



$SubTokenResponse = Invoke-RestMethod -Method Get -ContentType application/json -Uri $UserUri -Headers $Headers -SkipCertificateCheck
