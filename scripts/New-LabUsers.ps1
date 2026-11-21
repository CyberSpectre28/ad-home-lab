param([string]$CsvPath = "C:\Lab\users.csv")
Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName
$tempPassword = Read-Host "Temporary password for new users" -AsSecureString
$log = "C:\Lab\new-users-$(Get-Date -Format yyyyMMdd-HHmm).log"

Import-Csv $CsvPath | ForEach-Object {
    $sam = $_.Username
    if (Get-ADUser -filter "SamAccountName -eq '$sam'") {
	"SKIP $sam already exists" | Tee-Object -FilePath $log -Append
        return # Skips to the next row
    }
    New-ADUser -Name "$($_.FirstName) $($_.LastName)" `
	-GivenName $_.FirstName -Surname $_.LastName `
	-SamAccountName $sam -UserPrincipalName "$sam@lab.local" `
	-Department $_.Department -Title $_.Title `
	-Path "OU=$($_.Department), OU=Staff, $domainDN" `
	-AccountPassword $tempPassword -ChangePasswordAtLogon $true -Enabled $true
    Add-ADGroupMember -Identity "GG_$($_.Department)" -Members $sam
    "ADD    $sam -> $($_.Department)" | Tee-Object -FilePath $log -Append
}
