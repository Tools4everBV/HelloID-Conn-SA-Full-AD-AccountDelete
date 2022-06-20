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
}
catch {
    write-error "Could not delete AD user [$userPrincipalName]. Error: $($_.Exception.Message)" 
}
