
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
