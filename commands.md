# AD Home Lab: command reference

Every command used to build and run the lab, grouped by the machine it runs on.

| Label | Where to run it |
| --- | --- |
| Kali | Terminal on the Kali host (zsh) |
| DC01 | PowerShell as Administrator on the domain controller |
| CLIENT01 (user) | Normal PowerShell, signed in as a domain user |
| CLIENT01 (admin) | Terminal (Admin), elevated with an admin account |

- Placeholders are in angle brackets, such as `<name>`. Replace them, brackets included.
- Lab passwords are never written here. Commands that need one prompt for it.
- Run AD cmdlets only on DC01.
- Commands given only in chat are written in their standard form, so some flags may differ slightly from what was typed.

## Kali: VirtualBox and VM management

### Install VirtualBox

```bash
sudo apt update
sudo apt install -y virtualbox virtualbox-qt virtualbox-dkms virtualbox-guest-additions-iso
sudo reboot   # loads the VirtualBox kernel modules
```

### Lab network

```bash
VBoxManage list hostonlyifs                                     # find vboxnet0
VBoxManage dhcpserver modify --interface=vboxnet0 --disable     # DC01 hands out addresses instead
VBoxManage list dhcpservers
VBoxManage modifyvm DC01 --nic1 hostonly --hostonlyadapter1 vboxnet0 --nic2 nat
VBoxManage controlvm CLIENT01 setlinkstate2 off                 # unplug CLIENT01's internet adapter (on to reconnect)
VBoxManage controlvm DC01 clipboard mode bidirectional
```

### Start, save and stop

```bash
VBoxManage startvm DC01            # always start DC01 first, wait about a minute
VBoxManage startvm CLIENT01
VBoxManage list runningvms
VBoxManage controlvm CLIENT01 savestate   # save CLIENT01 first, then DC01
VBoxManage controlvm DC01 savestate
systemctl suspend                         # sleep Kali after both VMs are saved
```

### Snapshots

```bash
VBoxManage snapshot DC01 take "part8-done" --live
VBoxManage snapshot DC01 list
VBoxManage snapshot DC01 restore "part8-done"   # VM must be powered off or saved
```

### Screenshots and file copies

```bash
VBoxManage controlvm DC01 screenshotpng ~/ad-home-lab/screenshots/<NN-name>.png

read -rs "P?DC01 Administrator password: "; echo   # password stays out of history
VBoxManage guestcontrol DC01 copyfrom --username Administrator --password "$P" --target-directory ~/ad-home-lab/gpo/ 'C:\Lab\<file>'
unset P
```

### Host power checks

```bash
swapon --show        # little or no swap = hibernate and hybrid sleep aren't set up
cat /sys/power/disk
```

## Kali: Git, GitHub and the shell

### Install the GitHub CLI (not in Kali's repos)

```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install -y gh
```

### Create the repo

```bash
mkdir -p ~/ad-home-lab/{scripts,screenshots,gpo,tickets}
cd ~/ad-home-lab && git init
gh auth login
gh repo create ad-home-lab --public --source=. --push
```

### Everyday Git

```bash
git status
git add tickets screenshots && git commit -m "<message>" && git push
git log --oneline
echo '*.save' >> .gitignore    # ignore nano's backup files
```

### File checks

```bash
ls -l ~/ad-home-lab/screenshots/43*             # see when each file was last written
head -3 <file>                                  # check the first lines
file <file>                                     # check the encoding
find ~ -name "<pattern>" -mmin -30 2>/dev/null  # find a file changed in the last 30 minutes
xclip -selection clipboard < <file>             # copy a file's text to the clipboard
```

### nano and zsh tips

| Action | Keys or command |
| --- | --- |
| Save | Ctrl+O, then Enter |
| Exit | Ctrl+X (then N to quit without saving) |
| Cut a line | Ctrl+K |
| Paste into the terminal | Ctrl+Shift+V |
| Empty a file in zsh | `: > <file>` (a bare `>` waits for input) |
| Path with parentheses | Wrap it in quotes: `"<file>(1).ps1"` |

## DC01: domain build

### Network adapters

```powershell
Get-NetAdapter | Format-Table Name, InterfaceDescription, Status
Get-NetIPAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress
Rename-NetAdapter -Name "Ethernet" -NewName "Lab"          # check which is which first
Rename-NetAdapter -Name "Ethernet 2" -NewName "Internet"
New-NetIPAddress -InterfaceAlias "Lab" -IPAddress 192.168.56.10 -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Lab" -ServerAddresses 127.0.0.1
```

### AD DS, DNS and DHCP

```powershell
Install-WindowsFeature AD-Domain-Services, DHCP -IncludeManagementTools
Install-ADDSForest -DomainName "lab.local" -DomainNetbiosName "LAB" -InstallDns

Add-DhcpServerInDC -DnsName "dc01.lab.local" -IPAddress 192.168.56.10
Add-DhcpServerv4Scope -Name "Lab Workstations" -StartRange 192.168.56.100 -EndRange 192.168.56.200 -SubnetMask 255.255.255.0
Set-DhcpServerv4OptionValue -ScopeId 192.168.56.0 -DnsServer 192.168.56.10 -DnsDomain "lab.local"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12" -Name ConfigurationState -Value 2   # clears the DHCP warning
```

### Rename the DC after promotion (netdom)

Restart after `/makeprimary`, and only `/remove` the old name once DNS shows the new one.

```powershell
netdom computername WIN-7U4QHN5878R /add:DC01.lab.local
netdom computername WIN-7U4QHN5878R /makeprimary:DC01.lab.local
Restart-Computer
netdom computername DC01.lab.local /enumerate
netdom computername DC01 /remove:WIN-7U4QHN5878R.lab.local
```

### Health checks

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName
Get-DhcpServerv4Scope
Resolve-DnsName dc01.lab.local
dcdiag
Get-Service NTDS, DNS, Netlogon, DFSR, DHCPServer
Get-WinEvent -LogName "DFS Replication" -MaxEvents 10 | Format-Table TimeCreated, Id, Message -Wrap   # look for event 2213
Get-SmbShare SYSVOL, NETLOGON
```

### Join CLIENT01 (CLIENT01, admin)

```powershell
ipconfig /all
nslookup dc01.lab.local
Rename-Computer -NewName CLIENT01 -Restart
Add-Computer -DomainName "lab.local" -Credential LAB\Administrator -Restart
```

Then on DC01:

```powershell
Get-ADComputer CLIENT01 | Move-ADObject -TargetPath "OU=Workstations,$((Get-ADDomain).DistinguishedName)"
```

## DC01: OUs, groups and users

### OUs and department groups

```powershell
$domainDN = (Get-ADDomain).DistinguishedName
New-ADOrganizationalUnit -Name "Staff" -Path $domainDN
"IT", "Nursing", "Radiology", "Billing" | ForEach-Object {
    New-ADOrganizationalUnit -Name $_ -Path "OU=Staff,$domainDN"
    New-ADGroup -Name "GG_$_" -GroupScope Global -GroupCategory Security -Path "OU=Staff,$domainDN"
}
New-ADOrganizationalUnit -Name "Workstations" -Path $domainDN
New-ADOrganizationalUnit -Name "Disabled Users" -Path $domainDN
```

### Bulk-create users from the CSV

```powershell
notepad C:\Lab\users.csv          # header: FirstName,LastName,Username,Department,Title
C:\Lab\New-LabUsers.ps1            # prompts for the temporary password; skips existing users
Get-Content C:\Lab\new-users-*.log
```

### Fix CSV and naming mistakes

```powershell
Add-Content C:\Lab\users.csv "Jordan,Kim,jkim,IT,<Title>"                                   # append a missing row
(Get-Content C:\Lab\users.csv | Select-Object -SkipLast 1) | Set-Content C:\Lab\users.csv   # drop a bad last line
C:\Lab\Repair-LabUserNames.ps1                                                              # fixes the LastNmae header and names
Get-ADOrganizationalUnit -Filter "Name -eq 'Disabled USers'" | Rename-ADObject -NewName "Disabled Users"
```

### Check users and groups

```powershell
Get-ADUser -Filter * -SearchBase "OU=Staff,$((Get-ADDomain).DistinguishedName)" | Format-Table Name, SamAccountName
Get-ADGroupMember GG_Nursing | Format-Table Name, SamAccountName
Get-ADPrincipalGroupMembership dclarke | Format-Table Name
Get-ADUser pnair -Properties Enabled, LockedOut, PasswordLastSet | Format-List Name, Enabled, LockedOut, PasswordLastSet
```

## Group Policy

GPOs were built in the Group Policy Management console. These commands open it, apply policy and export proof.

### DC01

```powershell
gpmc.msc
Get-GPO -All | Format-Table DisplayName, GpoStatus
Get-GPOReport -Name "Workstation Security Baseline" -ReportType Html -Path C:\Lab\Workstation-Security-Baseline.html
Get-GPOReport -Name "Default Domain Policy" -ReportType Html -Path C:\Lab\Default-Domain-Policy.html
```

### CLIENT01

```powershell
gpupdate /force       # apply policy now
gpresult /r           # which GPOs applied to the computer and user
```

Use 64-bit Windows PowerShell. The x86 version lacks some cmdlets, such as `Get-LocalUser`.

## File shares

### Create and lock down the shares (DC01)

```powershell
"Nursing", "IT", "Public" | ForEach-Object { New-Item -Path "C:\Shares\$_" -ItemType Directory }

New-SmbShare -Name "Nursing" -Path "C:\Shares\Nursing" -FullAccess "LAB\Domain Admins" -ChangeAccess "LAB\GG_Nursing" -FolderEnumerationMode AccessBased
New-SmbShare -Name "IT"      -Path "C:\Shares\IT"      -FullAccess "LAB\Domain Admins" -ChangeAccess "LAB\GG_IT"      -FolderEnumerationMode AccessBased
New-SmbShare -Name "Public"  -Path "C:\Shares\Public"  -FullAccess "LAB\Domain Admins" -ChangeAccess "LAB\Domain Users"

icacls C:\Shares\Nursing /inheritance:r /grant "SYSTEM:(OI)(CI)F" "LAB\Domain Admins:(OI)(CI)F" "LAB\GG_Nursing:(OI)(CI)M"
icacls C:\Shares\IT      /inheritance:r /grant "SYSTEM:(OI)(CI)F" "LAB\Domain Admins:(OI)(CI)F" "LAB\GG_IT:(OI)(CI)M"
icacls C:\Shares\Public  /inheritance:r /grant "SYSTEM:(OI)(CI)F" "LAB\Domain Admins:(OI)(CI)F" "LAB\Domain Users:(OI)(CI)M"
```

### Check permissions (DC01)

```powershell
Get-SmbShare
Get-SmbShareAccess Nursing
icacls C:\Shares\Nursing
```

### Test access (CLIENT01, user)

```powershell
dir \\DC01\Nursing                 # lists files, or "Access is denied"
whoami                             # which account is running
whoami /groups | findstr GG_       # which department groups are in your token
net group GG_Nursing /domain       # current members, straight from the DC
klist                              # Kerberos tickets and when they were issued
klist | Select-String "Server:|Start Time:"
```

## Help desk tickets

### 001: Account lockout (DC01)

```powershell
Search-ADAccount -LockedOut | Format-Table Name, SamAccountName, LockedOut
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4740} -MaxEvents 3 | Format-List TimeCreated, Message
auditpol /set /subcategory:"User Account Management" /success:enable   # only if no 4740 events appear
Unlock-ADAccount -Identity mlopez
Get-ADUser mlopez -Properties LockedOut | Format-List Name, LockedOut
```

### 002: Password reset (DC01)

```powershell
Get-ADUser pnair -Properties Enabled, LockedOut, PasswordLastSet | Format-List Name, Enabled, LockedOut, PasswordLastSet
Set-ADAccountPassword -Identity pnair -Reset -NewPassword (Read-Host "Temporary password" -AsSecureString)
Set-ADUser -Identity pnair -ChangePasswordAtLogon $true
Get-ADUser pnair -Properties PasswordLastSet, PasswordExpired | Format-List Name, PasswordLastSet, PasswordExpired
```

### 003: Can't open the Nursing drive

```powershell
# DC01
Remove-ADGroupMember -Identity GG_Nursing -Members dclarke -Confirm:$false   # the simulated mistake
Get-ADPrincipalGroupMembership dclarke | Format-Table Name
Add-ADGroupMember -Identity GG_Nursing -Members dclarke                       # the fix

# CLIENT01 (user), then sign out and back in
whoami /groups | findstr GG_
net group GG_Nursing /domain
dir \\DC01\Nursing
klist | Select-String "Server:|Start Time:"
```

### 004: DNS misconfiguration (CLIENT01)

```powershell
# admin window: break and fix
Get-DnsClientServerAddress -AddressFamily IPv4 | Format-Table InterfaceAlias, ServerAddresses
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 8.8.8.8   # the simulated mistake
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ResetServerAddresses      # the fix: back to DHCP's DNS (DC01)
ipconfig /flushdns
ipconfig /renew

# user window: symptoms and diagnosis
gpupdate /force
dir \\lab.local\SYSVOL
Get-DnsClientServerAddress -InterfaceAlias Ethernet -AddressFamily IPv4
Test-NetConnection 192.168.56.10 -Port 445
nslookup lab.local
nslookup lab.local 192.168.56.10
```

If Terminal (Admin) opens Command Prompt (no `PS` in the prompt), type `powershell` first.

### 005: Offboarding (DC01)

```powershell
Get-ADUser kwalsh -Properties Enabled, MemberOf, Description | Format-List Name, Enabled, DistinguishedName, Description, MemberOf
notepad C:\Lab\Disable-LabUser.ps1
C:\Lab\Disable-LabUser.ps1 -Username kwalsh -Ticket 005
Get-Content C:\Lab\offboard-*.log
```

## Part 9 wrap-up (Kali)

```bash
read -rs "P?DC01 Administrator password: "; echo
VBoxManage guestcontrol DC01 copyfrom --username Administrator --password "$P" --target-directory ~/ad-home-lab/gpo/ 'C:\Lab\Workstation-Security-Baseline.html' 'C:\Lab\Default-Domain-Policy.html'
VBoxManage guestcontrol DC01 copyfrom --username Administrator --password "$P" --target-directory ~/ad-home-lab/scripts/ 'C:\Lab\Repair-LabUserNames.ps1' 'C:\Lab\users.csv' 'C:\Lab\New-LabUsers.ps1'
unset P

# GPO reports are saved as UTF-16; convert them so grep and GitHub can read them
cd ~/ad-home-lab/gpo && for f in *.html; do iconv -f UTF-16 -t UTF-8 "$f" > "$f.tmp" && mv "$f.tmp" "$f"; done && cd ~/ad-home-lab
file gpo/*.html

# safety check before publishing: only policy names, never real passwords
grep -io "password[^<]*" gpo/*.html | sort -u | head -20
```
