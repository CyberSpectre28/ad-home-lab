# Group Policy

| GPO | Linked to | Setting | Value | Why a hospital would use it |
| --- | --- | --- | --- | --- |
| Default Domain Policy | lab.local | Minimum password length | 12 | Longer passwords resist guessing |
| Default Domain Policy | lab.local | Account lockout threshold | 5 attempts / 15 min | Stops password-guessing attacks |
| Workstation Security Baseline | Workstations OU | Logon banner | "Authorized Use Only" | Legal notice; supports HIPAA access policies |
| Workstation Security Baseline | Workstations OU | Machine inactivity limit | 600 seconds | Locks unattended screens showing patient data |
| Workstation Security Baseline | Workstations OU | Removable storage | Deny all | Prevents patient data leaving on USB drives |
