function out-default {
  $input | Tee-Object -var global:lastobject | 
  Microsoft.PowerShell.Core\out-default
}

function Set-PSSessionConfigurationName {
    # Just toggles the PSSessionConfigurationName so you can psremote as 5 or 7 easily
    switch($PSSessionConfigurationName){
        "http://schemas.microsoft.com/powershell/Microsoft.PowerShell"  {"Switching to PowerShell.7"; $global:PSSessionConfigurationName = 'PowerShell.7'}
        "PowerShell.7"                                                  {"Switching to PowerShell.5"; $global:PSSessionConfigurationName = 'http://schemas.microsoft.com/powershell/Microsoft.PowerShell'}
    }
}

function hist { 
    #Copied from https://superuser.com/questions/1195895/view-full-history-for-powershell-not-just-current-session
    $find = $args; 
    Write-Host "Finding in full history using {`$_ -like `"*$find*`"}"; 
    Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object {$_ -like "*$find*"} | Get-Unique | more 
}