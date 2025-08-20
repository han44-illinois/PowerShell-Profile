function Uninstall-MatlabR2024bFromLab {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ComputerNameQuery
    )

    $comps = Get-ADComputer -Filter {Name -like $ComputerNameQuery} -SearchBase "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu"

    Write-Host "The following computers will have MATLAB R2024b uninstalled. Continue?"
    Write-Host $comps.Name
    $Confirm = Read-Host -Prompt "Y/N"

    switch ($Confirm.ToLower()) {
        "y" {Write-Host "Confirmed! Let's go!"}
        "n" {throw "You said no."}
        Default {throw "Huh?"}
    }
    
    $comps.name | ForEach-Object -ThrottleLimit 5 -Parallel {
        $MatlabUninstaller = "\\$_\c`$\Program Files\MATLAB\R2024b\bin\win64\MathWorksProductUninstaller.exe"
        $MatlabBinary = "\\$_\c`$\Program Files\MATLAB\R2024b\bin\matlab.exe"
        if((Test-Path $MatlabUninstaller) -and (Test-Path $MatlabBinary)){
            Invoke-Command -ComputerName $_ -ScriptBlock {
                Start-Process "C:\Program Files\MATLAB\R2024b\bin\win64\MathWorksProductUninstaller.exe" -ArgumentList "--mode silent" -Wait
            }
        }
        if(Test-Path $MatlabBinary){
            Write-Output "$_ Failed"
        }
        if(-not (Test-Path $MatlabBinary)){
            Write-Output $_
        }
    } | Sort-Object

    Write-Host "Install New Matlab?"
    $Confirm2 = Read-Host -Prompt "Y/N"

    switch ($Confirm2.ToLower()){
        "y" {Write-Host "Confirmed! Let's go!"}
        "n" {throw "You said no."}
        Default {throw "Huh?"}
    }

    $comps.name | ForEach-Object -ThrottleLimit 5 -Parallel {
        Invoke-MECMAppInstall -Computer $_ -AppName "Matlab" -Method Install
    } | Sort-Object -Property PSComputerName

}