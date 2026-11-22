# Ticket 003: "I can't open the Nursing drive"

| Field | Value |
|---|---|
| User | Devon Clarke (`dclarke`), Nursing |
| Device | CLIENT01 |
| Priority | High (no access to department files) |
| Status | Resolved |

## Setup (lab only)
To simulate a cleanup mistake, `dclarke` was removed from `GG_Nursing` with `Remove-ADGroupMember`.

## Symptoms
Opening N: returned "Windows cannot access \\DC01\Nursing. You do not have permission." `dir \\DC01\Nursing` returned "Access is denied." The N: drive still appeared in This PC because the mapping persisted from an earlier session.

## Diagnosis
- CLIENT01: `whoami /groups | findstr GG_` returned nothing, so `GG_Nursing` was missing from the user's token.
- DC01: `Get-ADPrincipalGroupMembership dclarke` showed only Domain Users, confirming the membership was removed in AD.

## Resolution
- `Add-ADGroupMember -Identity GG_Nursing -Members dclarke`
- User signed out and back in to get a new token.

## Verification
`whoami /groups` showed `LAB\GG_Nursing`, `dir \\DC01\Nursing` listed the share contents, and N: opened in Explorer.

## Lessons learned
- **Group changes only apply at sign-in.** Right after the removal, the user's existing session still had `GG_Nursing` in its token and could still open the share, even though `net group GG_Nursing /domain` showed she was no longer a member. Removing a group membership does not cut off an open session. That's why offboarding (Ticket 005) disables the account as well.
- **Local token and Kerberos tickets can disagree.** After the fix, the first sign-in still showed no `GG_Nursing` in `whoami /groups`, but the share opened. `klist` showed the Kerberos tickets were issued after the fix, so they carried the new membership. The local token was most likely built from cached credentials (Windows' fast logon optimization). A second sign-in brought the token up to date. In production, the Group Policy setting "Always wait for the network at computer startup and logon" prevents this.
- **Drive maps persist.** Group Policy Preferences drive maps stay on the client after targeting stops matching, unless "Remove this item when it is no longer applied" is enabled.

## Screenshots
- `40a-ticket3-stale-token-after-removal.png`: old session still has access after removal
- `40-ticket3-symptom.png`: access denied after a fresh sign-in
- `41-ticket3-diagnosis-dc.png`: AD membership confirms the cause
- `42-ticket3-fix.png`: user added back to GG_Nursing
- `43a-ticket3-klist.png`: Kerberos tickets issued after the fix
- `43-ticket3-fixed.png`: token shows GG_Nursing, share opens
- `43b-ticket3-fixed.png`: `whoami /groups` confirms GG_Nursing is in the token
