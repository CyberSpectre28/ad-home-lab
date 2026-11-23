# Repair-LabUserNames.ps1
# Fixes accounts created while users.csv had a misspelled header("LastNmae")
# which left Surname empty and Name as first name only.

# Fix the header(only the first line matches)
(Get-Content C:\Lab\users.csv) -replace '^FirstName,LastNmae,', 'FirstName,LastName,' | Set-Content C:\Lab\users.csv

# Stop here if the header still isn't right
$header = Get-Content C:\Lab\users.csv -TotalCount 1
if ($header -notlike "FirstName,LastName,*") { throw "Header is still wrong: $header" }
"Header OK: $header"

# Add the missing last names and rename each account to "First Last"
Import-Csv C:\Lab\users.csv | ForEach-Object {
    $u = Get-ADUser -Identity $_.UserName
    Set-ADUser -Identity $u -Surname $_.LastName -DisplayName "$($_.FirstName) $($_.LastName)"
    Rename-ADObject -Identity $u.DistinguishedName -NewName "$($_.FirstName) $($_.LastName)"
    "FIXED $($_.Username) -> $($_.FirstName) $($_.LastName)"
}