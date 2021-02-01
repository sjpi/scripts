Import-Module ActiveDirectory
$UserList = get-content C:\users\username\Desktop\Accounts.txt
Foreach ($Item in $UserList) {
$user = $null
$user =  Get-ADUser -Prop samAccountName,Enabled,AccountExpirationDate -filter {samAccountName -eq $Item}
if ($user)
    {
	$user | Select-Object samAccountName,Enabled,AccountExpirationDate | Out-File C:\users\username\Desktop\CheckedAccounts.txt -encoding default -append
    }
    else
    {
    "$item does not exist in AD" | Out-File C:\users\username\Desktop\CheckedAccounts.txt -encoding default -append
    }
}