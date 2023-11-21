<#
.SYNOPSIS
Use WSL2 to authenticate via Kerberos and get a certificate into that WSL2 instance.

.DESCRIPTION
Uses the Windows Credential Manager to store passwords safely, and retreive them for use in WSL2.
This focuses on a WSL2 kerberos certificate.

.PARAMETER WSLInstance
The name of the WSL2 instance/distro to use. Use `wsl -l` to see all valid instance names.

.PARAMETER Username
The username to use for the Kerberos authentication.

.PARAMETER SSOLookupName
The domain name for k5.

.EXAMPLE
Example usage of the script: 

        Get-WSLK5Certificate.ps1 -WSLInstance "Ubuntu-20.04" -Username "username" 

.NOTES

You will have had to install BetterCredentials for this to work:
    Install-Module BetterCredentials -AllowClobber

The first time you run this, you'll be prompted for your username at the command prompt. After that
it will be pulled from the Windows Credential Manager.

#>
function Get-WSLK5Certificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WSLInstance,
        [Parameter(Mandatory = $true)]
        [string]$Username,
        [string]$SSOLookupName = "CERN.CH"
    )

    # Grab the secure credential modeul from the Windows Vault.
    $password = BetterCredentials\Get-Credential -Store -inline -UserName $Username -Domain $SSOLookupName

    # Get the Domain\Username and convert them go USERNAME@DOMAIN.
    $DomainUsername = $password.UserName
    $parts = $DomainUsername.Split('\')
    $K5User = $parts[1] + "@" + $parts[0]

    # Get the plaintext password for a moment.
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password.Password)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Now, invoke it.
    wsl -d $WSLInstance bash -c "echo $PlainPassword | kinit $K5User"
}
