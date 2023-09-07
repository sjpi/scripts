#This script will check all domain servers for network connectivity, and will check tenant facing servers (session hosts, connection brokers, gateways, and web servers) for uptime in addition to network connectivity

#Get full list of domain computers
$ServerList = Get-ADComputer -Filter *
ForEach ($Server in $ServerList)
    {
#Ping each server in the server list    
    if (test-connection $Server.Name -count 1 -ErrorAction SilentlyContinue)
        {
#If the ping is successful get a list of roles/features installed on the server        
        $Roles = get-ciminstance win32_serverfeature -ComputerName $Server.Name -ErrorAction SilentlyContinue
#If ping was successful and a role with "Session Host" in the name is present, get the last boot time and uptime of that PC
        if ($Roles.Name -like '*Session Host*')
            {
#Stolen bit of script to get system information to turn into uptime
            $OS = Get-WmiObject win32_operatingsystem -ComputerName $server.Name
            $BootTime = $OS.ConvertToDateTime($OS.LastBootUpTime)
            $Uptime = $OS.ConvertToDateTime($OS.LocalDateTime) - $BootTime
#Make a list that shows, in order, computer name, if the ping succeeded, if uptime was checked based on role above, what the last boot time was, and what the total uptime is
            $propHash = [ordered]@{
                ComputerName  = $Server.Name
                PingSucceeded = 'Yes'
                CheckedUptime = 'Yes'
                LastBootTime  = $BootTime
                Uptime        = $Uptime
                }
            $objComputerUptime = New-Object PSOBject -Property $propHash
            $objComputerUptime
            }
#Do same as above but for roles with "Gateway" in the name
        ElseIf ($Roles.Name -like '*Gateway*')
            {
            $propHash = [ordered]@{
                ComputerName  = $Server.Name
                PingSucceeded = 'Yes'
                CheckedUptime = 'Yes'
                LastBootTime  = $BootTime
                Uptime        = $Uptime
                }
            $objComputerUptime = New-Object PSOBject -Property $propHash
            $objComputerUptime
            }
#Do same as above but for roles with "Connection Broker" in the name
         ElseIf ($Roles.Name -like '*Connection Broker*')
            {
            $propHash = [ordered]@{
                ComputerName  = $Server.Name
                PingSucceeded = 'Yes'
                CheckedUptime = 'Yes'
                LastBootTime  = $BootTime
                Uptime        = $Uptime
                }
            $objComputerUptime = New-Object PSOBject -Property $propHash
            $objComputerUptime
            }
#Do same as above but for roles with "URL Authorization" (web servers should have this) in the name
         ElseIf ($Roles.Name -like 'URL Authorization')
            {
            $propHash = [ordered]@{
                ComputerName  = $Server.Name
                PingSucceeded = 'Yes'
                CheckedUptime = 'Yes'
                LastBootTime  = $BootTime
                Uptime        = $Uptime
                }
            $objComputerUptime = New-Object PSOBject -Property $propHash
            $objComputerUptime
            }
#If the ping succeeded but it did not meet any of the above criteria, write server name, yes ping succeeded, no uptime was not checked
        Else
            {
                $NoUptime = [ordered]@{
                    ComputerName  = $server.name
                    PingSucceeded = 'Yes'
                    UptimeChecked = 'No'
                    LastBootTime  = 'N/A'
                    Uptime        = 'N/A'
                    }
                $objNoUptime = New-Object PSOBject -Property $NoUptime
                $objNoUptime
            }
        }
#If the ping failed, write that it failed, and that the uptime was not checked
    Else
        {
        $PingFailed = [ordered]@{
            ComputerName  = $server.Name
            PingSucceeded = 'No'
            UptimeChecked = 'No'
            LastBoottime  = 'N/A'
            Uptime        = 'N/A'
            }
        $objPingFailed = New-Object PSOBject -Property $PingFailed
        $objPingFailed
        }
    }