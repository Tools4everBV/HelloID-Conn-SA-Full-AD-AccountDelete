try{
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName }
    HID-Write-Status -Message "Found AD user [$userPrincipalName]" -Event Information
    HID-Write-Summary -Message "Found AD user [$userPrincipalName]" -Event Information
} catch {
    HID-Write-Status -Message "Could not find AD user [$userPrincipalName]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to find AD user [$userPrincipalName]" -Event Failed
}
 
try{
    Remove-ADObject -Identity $adUser.DistinguishedName -Recursive -Confirm:$false
    HID-Write-Status -Message "Finished deleting AD user [$userPrincipalName]" -Event Success
    HID-Write-Summary -Message "Successfully deleted AD user [$userPrincipalName]" -Event Success
} catch {
    HID-Write-Status -Message "Could not delete AD user [$userPrincipalName]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to delete AD user [$userPrincipalName]" -Event Failed
}