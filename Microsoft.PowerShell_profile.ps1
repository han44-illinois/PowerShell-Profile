foreach ($function in (Get-ChildItem "$($env:USERPROFILE)\Documents\PowerShell\Functions" -Recurse -File -Filter "*.ps1"))
{
  Write-Host "Importing $function"
    . $function.FullName
}

function out-default {
  $input | Tee-Object -var global:lastobject | 
  Microsoft.PowerShell.Core\out-default
}