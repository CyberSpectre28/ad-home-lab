# Ticket 002: "I lost my password"

| Field | Value |
|---|---|
| User | Priya Nair (`pnair`) |
| Device | CLIENT01 |
| Priority | Medium |
| Status | Resolved |

## Symptoms
New hire lost the temporary password issued on her first day and could not sign in.

## Diagnosis (DC01)
Checked the account before resetting it: enabled and not locked out, so a password reset was the right fix (not an unlock). `PasswordLastSet` was blank, confirming she had never completed her first sign-in.

## Resolution
- Reset the password to a one-time temporary value with `Set-ADAccountPassword -Reset`. The value was entered as a secure string, so it never appears in the shell history.
- Set `ChangePasswordAtLogon` so the temporary password only works once.
- Confirmed `PasswordExpired : True` with `Get-ADUser`.
- In production, the user's identity would be verified first, and the temporary password given over a separate channel (phone or in person, not email).

## Verification
User signed in with the temporary password, was forced to choose a new one, and reached the desktop. `whoami` returned `lab\pnair`.

## Notes
The help desk never learns the user's real password. They only set a one-time value. The new password still had to meet the domain policy (12+ characters, complexity). The domain's password history also blocks reusing recent passwords.

## Screenshots
- `37-ticket2-reset.png`: account check, reset, PasswordExpired True
- `38-ticket2-must-change.png`: forced password change at sign-in
- `39-ticket2-login-ok.png`: successful sign-in
