function Invoke-CCMCacheCleanup {
    param (
        [string]$Computer
    )

    if(Test-Connection $Computer -Count 1 -Quiet){
        Write-Host "$Computer successfully pinged, clearing its ccmcache."
        Push-Location -Path "C:\engrit"
        $NumFolders = Get-ChildItem -Path "\\$Computer\c`$\Windows\ccmcache"
        Write-Host "Removing $NumFolders folders from $Computer's ccmcache."
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            [__comobject]$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
            $CacheInfo = $CCMComObject.GetCacheInfo().GetCacheElements()
            foreach ($CacheItem in $CacheInfo) {
            $null = $CCMComObject.GetCacheInfo().DeleteCacheElement([string]$($CacheItem.CacheElementID))}
        }
        Pop-Location
    }
    
}