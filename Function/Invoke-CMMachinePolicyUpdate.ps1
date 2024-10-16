function Invoke-CMMachinePolicyUpdate {

    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [String] $CollectionName,
        [Int] $Delay = 120,
        [Switch] $PassThru
    )

    BEGIN{    
        Write-Host "Starting at $(Get-Date -DisplayHint Time)"
        if($pwd.Path -ne "MP0:\"){
            Push-Location
            Prep-MECM
        }
    }

    PROCESS{
        Write-Host "Waiting $Delay Seconds..."
        Start-Sleep -Seconds $Delay

        Write-Host "$(Get-Date -DisplayHint Time) Pushing Policy Update..."
        Invoke-CMClientAction -CollectionName $CollectionName -ActionType ClientNotificationRequestMachinePolicyNow
    }

    END{
        Write-Host "Done at $(Get-Date -DisplayHint Time)"
    }
}