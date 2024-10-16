function Invoke-CMMachinePolicyUpdate {

    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [String] $CollectionName,
        [Int] $Delay,
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
        if($Delay -gt 0){
            Write-Host "Waiting $Delay Seconds..."
            Start-Sleep -Seconds $Delay
        }

        Write-Host "$(Get-Date -DisplayHint Time) Pushing Policy Update..."
        Invoke-CMClientAction -CollectionName $CollectionName -ActionType ClientNotificationRequestMachinePolicyNow
    }

    END{
        Write-Host "Done at $(Get-Date -DisplayHint Time)"
    }
}