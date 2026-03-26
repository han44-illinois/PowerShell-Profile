function Get-OfflineSystemHistory {
param(
    [Parameter(Mandatory)]
    [string]$Year,
    [Parameter(Mandatory)]
    [string]$Month,
    [ValidateSet('Windows','Linux')]
    [string]$OS
    )

    $Output = Get-ChildItem -Path "\\engr-is-auto01\share\automations\data\get-offline-systems-output\offline-systems_$Year-$Month*.csv" | 
        ForEach-Object { Get-Content -Path $_ | ConvertFrom-Csv -Header "name","os" }
        
    if($OS){
        $Output = $Output | Where-Object {$_.os -eq $OS}
    }

    $Output = $Output | Select-Object -ExpandProperty name | 
    Group-Object | 
    Select-Object -Property Count,Name | 
    Sort-Object -Property Count -Descending

    $Output
}