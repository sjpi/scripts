﻿# get Firefox process
$firefox = Get-Process mstsc -ErrorAction SilentlyContinue
if ($firefox) {
  # try gracefully first
  $firefox.CloseMainWindow()
  # kill after five seconds
  Sleep 5
  if (!$firefox.HasExited) {
    $firefox | Stop-Process -Force
  }
}
Remove-Variable mstsc