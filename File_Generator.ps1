# cd to user desktop
Set-Location "$env:USERPROFILE\Desktop"


# Creates a GIU to select a file
function Select-File {
    Add-Type -AssemblyName System.Windows.Forms
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.InitialDirectory = $env:USERPROFILE
    $OFD.Title = "Select Key"
    [void]$OFD.ShowDialog()
    return $OFD.FileName

}


# Generates key file to decrypt the password
function Generate-Key {

    # Creates byte array for a 256-bit key
    [byte[]] $key = (1..32)

    # Random key generation
    for ($index = 0; $index -lt $key.Count; $index++) {

        $key[$index] = Get-Random -Maximum 255 -Minimum 0

    }

    # Creates key file with semi-random file name
    $key | Out-File $(([double]((Get-Date -Format o).Replace('-','').Replace(':','').Replace('.','').replace('T','')) * (2)).ToString()).Replace('.','').Replace('+','').Replace('E','') -Force

}


# Encrypts Password
function Generate-Secret {
    
    $SecretString = Read-Host Enter service account password -AsSecureString
    $EncryptedSecret = ConvertFrom-SecureString -SecureString $SecretString -Key $(Get-Content $(Select-File))
    $EncryptedSecret | Out-File $(([double]((Get-Date -Format o).Replace('-','').Replace(':','').Replace('.','').replace('T','')) / (2)).ToString()).Replace('.','').Replace('+','').Replace('E','') -Force

}


Generate-Key
Generate-Secret
