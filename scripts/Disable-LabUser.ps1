<#
.SYNOPSIS
  Offboards a lab user: disables the account, scrambles the password,
  removes group memberships, stamps the description, and moves the
  account to the Disabled Users OU. Every step is logged.
.EXAMPLE
  .\Disable-LabUser.ps1 -Username kwalsh -Ticket 005
#>
param(
    [Parameter(Mandatory)][string]$Username,
    [Parameter(Mandatory)][string]$Ticket
)

Import-Module ActiveDirectory
$ErrorActionPreference = 'Stop'
$log = "C:\Lab\offboard-$(Get-Date -Format yyyyMMdd).log"

function Write-Log($msg) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg"
    Add-Content -Path $log -Value $line
    Write-Output $line
}

$user = Get-ADUser -Identity $Username -Properties MemberOf, Enabled
$disabledOU = (Get-ADOrganizationalUnit -Filter "Name -eq 'Disabled Users'").DistinguishedName
if (-not $disabledOU) { throw "Disabled Users OU not found" }
if (-not $user.Enabled) { Write-Log "WARNING $Username was already disabled" }

Write-Log "START $Username ticket $Ticket by $env:USERNAME"

# 1. Disable the account
Disable-ADAccount -Identity $user
Write-Log "DISABLED $Username"

# 2. Scramble the password (random 24 characters + a suffix that guarantees complexity)
$chars  = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%'
$random = (-join (1..24 | ForEach-Object { $chars | Get-Random })) + 'Aa1!'
Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString $random -AsPlainText -Force)
$random = $null
Write-Log "PASSWORD SCRAMBLED $Username"

# 3. Remove group memberships (Domain Users is the primary group and stays)
foreach ($groupDN in $user.MemberOf) {
    $group = Get-ADGroup -Identity $groupDN
    Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false
    Write-Log "REMOVED $Username from $($group.Name)"
}

# 4. Stamp the description
Set-ADUser -Identity $user -Description "Disabled $(Get-Date -Format yyyy-MM-dd) by $env:USERNAME - ticket $Ticket"
Write-Log "DESCRIPTION SET $Username"

# 5. Move to the Disabled Users OU
Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU
Write-Log "MOVED $Username to $disabledOU"

Write-Log "DONE $Username"
