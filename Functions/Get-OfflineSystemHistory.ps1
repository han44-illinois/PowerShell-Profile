function Get-OfflineSystemHistory {
param(
    [Parameter(Mandatory, ParameterSetName = 'Current')]
    [switch]$Current,

    [Parameter(ParameterSetName = 'Current')]
    [switch]$OpenSheet,

    [Parameter(Mandatory, ParameterSetName = 'History')]
    [string]$Year,

    [Parameter(Mandatory, ParameterSetName = 'History')]
    [string]$Month,

    [Parameter(ParameterSetName = 'History')]
    [ValidateSet('Windows','Linux')]
    [string]$OS
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Current' {
            $Output = Get-Content -Path "\\engr-is-auto01\share\automations\data\get-offline-systems-output\offline-systems_latest.tsv"
            $Output | Set-Clipboard
            Write-Host "Latest offline system sheet has been copied to your clipboard!"
            if($OpenSheet){
                Start-Process "https://docs.google.com/spreadsheets/d/1-LmMafGDrZ8bKzfWLA2UbbdQd2S92_Smi1yT-eetWNk/edit?gid=0#gid=0"
            }
        }
        'History' {
            $Output = Get-ChildItem -Path "\\engr-is-auto01\share\automations\data\get-offline-systems-output\offline-systems_$Year-$Month*.csv" | 
                ForEach-Object { Get-Content -Path $_ | ConvertFrom-Csv -Header "name","os" }
            
            if($OS){
                $Output = $Output | Where-Object {$_.os -eq $OS}
            }

            $Output = $Output | Select-Object -ExpandProperty name | 
            Group-Object | 
            Select-Object -Property Count,Name | 
            Sort-Object -Property Count -Descending
        }
    }

    $Output
}