# Group Policy

GPOs configured in the lab, what each setting does, and why a hospital would use it.

| GPO | Linked to | Setting | Value | Why a hospital would use it |
| --- | --- | --- | --- | --- |
| Default Domain Policy | lab.local | Minimum password length | 12 | Longer passwords resist guessing |
| Default Domain Policy | lab.local | Account lockout threshold | 5 attempts | Stops password-guessing attacks |
| Default Domain Policy | lab.local | Lockout duration / reset counter | 15 minutes | Locked accounts recover on their own without a help desk call |
| Workstation Security Baseline | Workstations OU | Logon banner | "Authorized Use Only" + PHI notice | Legal notice; supports HIPAA access policies |
| Workstation Security Baseline | Workstations OU | Machine inactivity limit | 600 seconds | Locks unattended screens showing patient data |
| Workstation Security Baseline | Workstations OU | Removable storage | Deny all | Prevents patient data leaving on USB drives |

## Notes
- Domain-wide password and lockout rules only take effect from a GPO linked at the domain level, which is why they are set in the Default Domain Policy.
- Verified on CLIENT01 with `gpresult /r /scope computer` (see screenshot 23).
- Full HTML reports: `Workstation-Security-Baseline.html`, `Default-Domain-Policy.html` (exported with `Get-GPOReport`).
