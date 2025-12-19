function Invoke-CMCollectionUpdateForInstantImaging {
    [CmdletBinding()]
    param()

    BEGIN{    
        Write-Host "Starting at $(Get-Date -DisplayHint Time)"
        if($pwd.Path -ne "MP0:\"){
            Push-Location
            Prep-MECM
        }
        $TSCollection = "UIUC-ENGR-IS Deploy OSD TS (Win11 2025a, Available, with SC)"
        $TSNoMaintCollection = "UIUC-ENGR-IS Deploy OSD Available TS + No Maintenance Window"
    }

    PROCESS {
        Invoke-CMDeviceCollectionUpdate -Name $TSNoMaintCollection
        Invoke-CMDeviceCollectionUpdate -Name $TSCollection
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Maint Window - Exclude from ALL windows"
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Maint Window - Exclude from Standard window"
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Maint Window - Machines not in ANY maint window collection"
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Maint Window - Standard window"
        Write-Host "$(Get-Date -DisplayHint Time) Collection updates initiated! Try Invoke-TaskSequence in like 15 minutes."
        Write-Host "$(Get-Date -DisplayHint Time) Waiting 15 minutes to push policy..."

        Start-Sleep -Seconds 900
        Invoke-CMClientAction -CollectionName $TSNoMaintCollection -ActionType ClientNotificationRequestMachinePolicyNow

        $DeploymentID = (Get-CMDeployment -CollectionName $TSCollection).DeploymentID
        Write-Host "Reminder: When you're ready, invoke task sequence with deployment id $DeploymentID"
    }

    END {
        Pop-Location
    }
}