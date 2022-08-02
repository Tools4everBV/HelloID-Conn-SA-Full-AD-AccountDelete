$userPrincipalName = $form.grid.UserPrincipalName

try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName }
    write-information "Found AD user [$userPrincipalName]"
}
catch {
    write-error "Could not find AD user [$userPrincipalName]. Error: $($_.Exception.Message)"
}

try {
    Remove-ADObject -Identity $adUser.DistinguishedName -Recursive -Confirm:$false
    write-information "Finished deleting AD user [$userPrincipalName]"
    $Log = @{
            Action            = "DeleteAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Successfully deleted AD user $userPrincipalName" # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.Name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log
}
catch {
    write-error "Could not delete AD user [$userPrincipalName]. Error: $($_.Exception.Message)" 
    $Log = @{
            Action            = "DeleteAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Failed to delete AD user $userPrincipalName" # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.Name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log
}
