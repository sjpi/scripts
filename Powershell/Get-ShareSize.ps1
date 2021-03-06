function Get-ShareSize {
    Param(
    [String[]]$ComputerName = $env:computername
    )

Begin{$objFldr = New-Object -com Scripting.FileSystemObject}

Process{
    foreach($Computer in $ComputerName){
        Get-WmiObject Win32_Share -ComputerName $Computer -Filter "not name like '%$'" | %{
            $Path = $_.Path -replace 'C:',"\\$Computer\c$"
            $Size = ($objFldr.GetFolder($Path).Size) / 1GB
            New-Object PSObject -Property @{
            Name = $_.Name
            Path = $Path
            Description = $_.Description
            Size = $Size
            }
        }
    }
}
}