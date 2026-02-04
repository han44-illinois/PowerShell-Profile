function Remove-CMDeploymentsToTestCollection {
    [CmdletBinding()]
    param (
        $CollectionName = "UIUC-ENGR-IS James' testing"
    )
    
    begin {
        $myPWD = $pwd.Path
        Prep-MECM
    }
    
    process {
        $Deployments = Get-CMDeployment -CollectionName $CollectionName
        $Selection = $Deployments | Out-GridView -PassThru
        $Selection | ForEach-Object {
            Write-Host "Removing deployment for $($_.ApplicationName) from $CollectionName"
            Remove-CMDeployment -DeploymentId "$($_.DeploymentID)" -ApplicationName "$($_.ApplicationName)" -Force
        }
    }
    
    end {
        Set-Location $myPWD
    }
}