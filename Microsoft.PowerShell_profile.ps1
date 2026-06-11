foreach ($function in (Get-ChildItem "$($env:USERPROFILE)\Documents\PowerShell\Functions" -Recurse -File -Filter "*.ps1"))
{
    Write-Host "Importing $function"
    . $function.FullName
}

function out-default {
  $input | Tee-Object -var global:lastobject | 
  Microsoft.PowerShell.Core\out-default
}

Set-PSReadLineOption -PredictionViewStyle ListView

$PSDefaultParameterValues.Add('Get-MachineInfo:OUDN',"OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu")
$PSDefaultParameterValues.Add('Get-MachineInfo:PassThru',$true)