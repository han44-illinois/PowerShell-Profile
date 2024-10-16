function hist { 
    #Copied from https://superuser.com/questions/1195895/view-full-history-for-powershell-not-just-current-session
    $find = $args; 
    Write-Host "Finding in full history using {`$_ -like `"*$find*`"}"; 
    Get-Content (Get-PSReadlineOption).HistorySavePath | Where-Object {$_ -like "*$find*"} | Get-Unique | more 
}