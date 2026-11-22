# Ticket 001: "My account is locked"

| Field | Value |
|---|---|
| User | Maria Lopez (`mlopez`), Nursing |
| Device | CLIENT01 |
| Priority | High (user can't work) |
| Status | Resolved |

## Symptoms
User reported she could not sign in to CLIENT01. After several wrong passwords, Windows 11 began delaying attempts ("Invalid credentials, delaying next attempt"). The next attempt returned: "The referenced account is currently locked out and may not be logged on to."

## Diagnosis (DC01)
- `Search-ADAccount -LockedOut` confirmed `mlopez` was locked.
- Security event **4740** on DC01 showed the account was locked by the domain controller, with **Caller Computer Name: CLIENT01**. This confirmed the failed attempts came from her own workstation and not from another device holding a stale password.

## Root cause
Five failed sign-ins in a row triggered the domain lockout policy set in the Default Domain Policy (threshold 5 attempts, 15-minute lockout).

## Resolution
- `Unlock-ADAccount -Identity mlopez`
- Confirmed `LockedOut : False` with `Get-ADUser`.
- In production, the user's identity would be verified before unlocking.

## Verification
User signed in successfully with her correct password. `whoami` returned `lab\mlopez`.

## Notes
Two protection layers were observed. Windows 11 throttles repeated bad attempts locally, and the domain then locks the account after 5 failures. If lockouts kept recurring, the next step would be checking event 4740's caller computer for saved credentials (mapped drives, phones, scheduled tasks).

## Screenshots
- `33a-ticket1-login-throttling.png`: Windows 11 delaying attempts
- `33-ticket1-locked-out.png`: lockout message on CLIENT01
- `34-ticket1-diagnosis.png`: locked account and event 4740
- `35-ticket1-unlocked.png`: unlocked, LockedOut False
- `36-ticket1-login-ok.png`: successful sign-in
