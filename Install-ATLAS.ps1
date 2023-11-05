param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [ValidateSet('EL9', 'CENTOS7')]
    [string]$OS = 'CENTOS7'
)

# The first thing to do is install a WSL distro. The mapping is:
# EL9 -> "AlmaLinux 9" (MS Store name)
# CENTOS07 ->  "CentOS 7" (MS Store name)
# May need to follow the following: https://learn.microsoft.com/en-us/windows/wsl/use-custom-distro
# And the twiki that shows you how to install CENTOS7:https://twiki.cern.ch/twiki/bin/view/Sandbox/RunningATLASOnWSL2 (from Atilla)

if ("$OS" -eq "CENTOS7") {
    Write-Host "Downloading the CENTOS7 distro from github in your Downloads folder..."

    # Find the CENTOS7 from github at https://github.com/mishamosher/CentOS-WSL/releases/download/7.9-2211/CentOS7.zip
    # We first download it to the Downloads folder.
    
    $CENTOS7 = "$env:USERPROFILE\Downloads\CentOS7.zip"

    if (-not $(Test-Path $CENTOS7)) {
        Invoke-WebRequest -Uri "https://github.com/mishamosher/CentOS-WSL/releases/download/7.9-2211/CentOS7.zip" -OutFile $CENTOS7
    }
    
    # Unzip the file in the Downloads folder
    $CENTOS7Extracted = "$env:USERPROFILE\Downloads\CentOS7"
    if (-not $(Test-Path $CENTOS7Extracted)) {
        Expand-Archive -Path $CENTOS7 -DestinationPath $CENTOS7Extracted
    }
}
elseif ($OS -eq 'EL9') {
    Write-Host "Downlaoding EL9 disto is not yet supported"
    exit
}
else {
    Write-Host "OS $OS is not supported"
    exit
}

Write-Host "Installing ATLAS for $Name on $OS..."
# Add your installation logic here
