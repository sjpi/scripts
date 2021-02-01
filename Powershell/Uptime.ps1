# This PS script provides Uptime and Ping results for list of computers.
		$names = Get-Content "C:\mowens\servers.txt"
        @(
		   foreach ($name in $names)
	      {
            if ( Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue ) 
		  {
            $wmi = gwmi -class Win32_OperatingSystem -computer $name
		    $LBTime = $wmi.ConvertToDateTime($wmi.Lastbootuptime)
		    [TimeSpan]$uptime = New-TimeSpan $LBTime $(get-date)
		    Write-output "$name Uptime is  $($uptime.days) Days $($uptime.hours) Hours $($uptime.minutes) Minutes $($uptime.seconds) Seconds"
					
		  }
             else {
                Write-output "$name is not pinging"
		          }
       		}
		 ) | Out-file -FilePath "c:\Uptimes.txt"
		 

		

    