[CmdletBinding()] 
 
param( 
    [Parameter(Mandatory=$True, Helpmessage="Specify full path to CSV")] 
    [string]$CSV    
) 
BEGIN{ 
    #Checks if the user is in the administrator group. Warns and stops if the user is not. 
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(` 
        [Security.Principal.WindowsBuiltInRole] "Administrator")) 
    { 
        Write-Warning "You are not running this as local administrator. Run it again in an elevated prompt." 
        Break 
    } 
    try { 
    Import-Module ActiveDirectory 
    } 
    catch { 
    Write-Warning "The Active Directory module was not found" 
    } 
    try { 
    $Users = Import-CSV $CSV 
    } 
    catch { 
    Write-Warning "The CSV file was not found" 
    } 
} 
PROCESS{ 
 
    foreach($User in $Users){ 
        try{ 
            Add-ADGroupMember $User.Group -Members $User.User -ErrorAction Stop -Verbose 
        } 
        catch{ 
        } 
 
    } 
} 
END{ 
  
}