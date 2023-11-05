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
