param(
    [Parameter(Mandatory = $true)]
    [string]$DistroName
)

# Copy all files from OneDrive, so locate OneDrive on the current install:
$OneDrive = "$env:USERPROFILE\OneDrive"
if (-not $(Test-Path $OneDrive)) {
    Write-Host "OneDrive not found at $OneDrive"
    exit
}

# Copy in all .ssh files from the OneDrive folder "ssh\ssh config files" to the
# wsl distro's .ssh folder for the default user.
$SSHConfigFiles = "$OneDrive\.ssh\ssh config files"
if (-not $(Test-Path $SSHConfigFiles)) {
    Write-Host "SSH config files not found at $SSHConfigFiles"
    exit
}
$allFiles = Get-ChildItem -Path $SSHConfigFiles

# Filter out and keep "config", and any ".pub" files.
$allFiles = $allFiles | Where-Object { $_.Name -eq "config" -or $_.Name -notlike "*.pub" }

# Next, copy all the flies in $SSHConfigFiles to the .ssh folder in the distro
# (which is at /home/<user>/.ssh)
function ConvertTo-WslPath ($windowsPath) {
    $drive = $windowsPath.Substring(0, 1).ToLower()
    $path = $windowsPath.Substring(2).Replace('\', '/')
    return "/mnt/$drive$path"
}

function Test-RSAFile ($windowsPath) {
    # Return true if the file's contents has "-----BEGIN RSA PRIVATE KEY-----"
    # on the first line.
    $firstLine = Get-Content $windowsPath | Select-Object -First 1
    return $firstLine -like "*BEGIN RSA PRIVATE KEY*"
}

wsl -d $DistroName mkdir -p ~/.ssh

foreach ($file in $allFiles) {
    $windowsPath = $file.FullName
    $wslFile = ConvertTo-WslPath $windowsPath
    wsl -d $DistroName cp $wslFile ~/.ssh

    if (Test-RSAFile($windowsPath)) {
        wsl -d $DistroName chmod 600 ~/.ssh/$($file.Name)
    }
}

# Now prepare the .globus files. They are in the OneDrive foler "CERNCert"
# It should be the only .p12 file in the directory
$CERNCert = "$OneDrive\.ssh\CERNCert"
if (-not $(Test-Path $CERNCert)) {
    Write-Host "CERN Certificates not found at $CERNCert"
    exit
}
$p12Files = Get-ChildItem -Path $CERNCert -Filter "*.p12"
if ($p12Files.Count -ne 1) {
    Write-Host "Found $($p12Files.Count) .p12 files in $CERNCert. There should be only one."
    exit
}
$p12File = $p12Files[0]

wsl -d $DistroName mkdir -p ~/.globus
$wslFIle = ConvertTo-WslPath $p12File.FullName
wsl -d $DistroName cp $wslFile ~/.globus/myCert.p12

Write-Host "Installing Globus certificates. You'll be prompted for the pass phrase for your p12 file"
Write-Host "and then a pass phrase for the userkey.pem file."
wsl -d $DistroName openssl pkcs12 -nocerts -in ~/.globus/myCert.p12 -out ~/.globus/userkey.pem
Write-Host "And again for the p12 file to generate the usercert.pem"
wsl -d $DistroName openssl pkcs12 -clcerts -nokeys -in ~/.globus/myCert.p12 -out ~/.globus/usercert_noText.pem
wsl -d $DistroName bash -c "openssl x509 -in ~/.globus/usercert_noText.pem -text > ~/.globus/usercert.pem"
wsl -d $DistroName rm ~/.globus/usercert_noText.pem
wsl -d $DistroName chmod 444 ~/.globus/usercert.pem
wsl -d $DistroName chmod 400 ~/.globus/userkey.pem
