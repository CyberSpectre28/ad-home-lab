
# AD Home Lab - Build Log
## 2026-11-20 - Setup
- Did: installed VirtualBox on Kali, created host-only network vboxnet0 (192.168.56.1). disabled VirtualBox DHCP. set up GitHub repo with gh
- Problem: `gh` package not found in Kali repos
- Fix: installed GitHub CLI from GitHub's official apt repository

## To do
- [ ] README: add note that lab passwords are intentionally simple and not stored in the repo


## 2026-11-21 – Part 5: CLIENT01
- Did: built Windows 11 Enterprise LTSC client, got IP from DC01's DHCP (192.168.56.100), renamed, joined lab.local, moved to Workstations OU, logged in as LAB\dclarke with forced password change
- Problem: host restarted unexpectedly with VMs running
- Fix: verified DC health (services, SYSVOL/NETLOGON, DFSR, dcdiag) – all passed
- Note: nslookup "Server: UnKnown" is a missing reverse lookup zone, not an error


## 2026-11-22 – Part 6: Group Policy
- Did: set domain password policy (12 chars) and lockout (5 attempts / 15 min); created Workstation Security Baseline GPO (logon banner, 10-min screen lock, USB storage blocked) linked to Workstations OU; verified on CLIENT01 with gpresult and the logon banner
- Learned: domain password rules only work from a domain-linked GPO; "Allow Administrator account lockout" is now on by default
- Fix: removed a stray nano .save file from the repo and added .gitignore
## 2026-11-22 – Part 7: File shares
- Did: created Nursing, IT and Public shares with share + NTFS permissions (inheritance removed, groups get Modify); mapped N: for GG_Nursing via Group Policy Preferences with item-level targeting
- Tested: Maria sees shares, is denied IT, can write to Nursing, gets N:; Alex (IT) gets no N:
- Learned: access-based enumeration hides folders inside a share, not the shares themselves; share and NTFS permissions both apply, and the stricter wins
## Part 8: Help desk tickets
- Worked 5 tickets end to end: account lockout, password reset, group access, DNS misconfiguration, offboarding.
- Write-ups in `tickets/`, offboarding script in `scripts/Disable-LabUser.ps1`.
- Snapshots: `part8-done` on DC01 and CLIENT01.

## Part 9: Documentation
- Exported GPO reports to `gpo/` (converted from UTF-16 to UTF-8 for GitHub).
- Copied the final scripts and user CSV from DC01.
- Wrote the README and the command reference.
