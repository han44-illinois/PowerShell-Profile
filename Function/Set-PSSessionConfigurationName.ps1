function Set-PSSessionConfigurationName {
    # Just toggles the PSSessionConfigurationName so you can psremote as 5 or 7 easily
    switch($PSSessionConfigurationName){
        "http://schemas.microsoft.com/powershell/Microsoft.PowerShell"  {"Switching to PowerShell.7"; $global:PSSessionConfigurationName = 'PowerShell.7'}
        "PowerShell.7"                                                  {"Switching to PowerShell.5"; $global:PSSessionConfigurationName = 'http://schemas.microsoft.com/powershell/Microsoft.PowerShell'}
    }
}