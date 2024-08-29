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

function Invoke-CMCollectionUpdateForImaging {

    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [String] $ComputerName,
        [Int] $CheckingIntervalInSeconds = 120,
        [Int] $CheckLimitCount = 20,
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

        $ComputerExists = $false
        $CheckCount = 0
        while ((-not $ComputerExists) -and ($CheckCount -le $CheckLimitCount)){
            $DeviceCheck = Get-CMDevice -Name $ComputerName -Resource
            if($DeviceCheck){
                $ComputerExists = $true
                Write-Host "Device discovered at $(Get-Date -DisplayHint Time)"
            }else{
                Write-Host "Device not found! Trying again in $CheckingIntervalInSeconds Seconds. $($CheckLimitCount - $CheckCount) attempts remaining."
                Start-Sleep -Seconds $CheckingIntervalInSeconds
                $CheckCount++
            }
            
        }

        $CollectionCheck = Get-CMCollectionMember -CollectionName "UIUC-ENGR-IS OSD TS (Win11 2023c, Available, no SC)" -Name $ComputerName

        if(-not $CollectionCheck){
            Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-Devices without MECM client"
            Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-Instructional plus devices without MECM client"
            Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS OSD TS (Win11 2023c, Available, no SC)"
            
            $ComputerExistsInCollection = $false
            $CheckCount = 0

            while((-not $ComputerExistsInCollection) -and ($CheckCount -le $CheckLimitCount)){
                $CollectionCheck = Get-CMCollectionMember -CollectionName "UIUC-ENGR-IS OSD TS (Win11 2023c, Available, no SC)" -Name $ComputerName
                if($CollectionCheck){
                    $ComputerExistsInCollection = $true
                    Write-Host "Device in collection at $(Get-Date -DisplayHint Time)"
                    if($PassThru){
                        Write-Output $CollectionCheck
                    }
                }else{
                    Write-Host "Device not found in the imaging collection! Trying again in $CheckingIntervalInSeconds Seconds. $($CheckLimitCount - $CheckCount) attempts remaining."
                    $CheckCount++
                    Start-Sleep -Seconds $CheckingIntervalInSeconds
                }
            }
        }
    }

    END{
        Pop-Location
    }
}

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

function Invoke-CMCollectionUpdateForInstantImaging {
    [CmdletBinding()]
    param()

    BEGIN{    
        Write-Host "Starting at $(Get-Date -DisplayHint Time)"
        if($pwd.Path -ne "MP0:\"){
            Push-Location
            Prep-MECM
        }
    }

    PROCESS {
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS OSD TS + No Maintenance Window"
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS OSD TS (Win11 2023c, Available, with SC)"
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Maint Window - Exclude from ALL windows"
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Maint Window - Exclude from Standard window"
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Maint Window - Machines not in ANY maint window collection (Alternate)"
        Invoke-CMDeviceCollectionUpdate -Name "UIUC-ENGR-IS Maint Window - Standard window"
        Write-Host "$(Get-Date -DisplayHint Time) Collection updates initiated! Try Invoke-TaskSequence in like 15 minutes."
        Write-Host "$(Get-Date -DisplayHint Time) Waiting 15 minutes to push policy..."

        Invoke-CMMachinePolicyUpdate -CollectionName "UIUC-ENGR-IS OSD TS + No Maintenance Window" -Delay 900
        $DeploymentID = (Get-CMDeployment -CollectionName "UIUC-ENGR-IS OSD TS (Win11 2023c, Available, with SC)").DeploymentID
        Write-Host "Reminder: When you're ready, invoke task sequence with deployment id $DeploymentID"
    }

    END {
        Pop-Location
    }
}