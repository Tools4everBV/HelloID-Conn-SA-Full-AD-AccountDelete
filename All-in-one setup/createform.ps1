
#HelloID variables
$PortalBaseUrl = "https://CUSTOMER.helloid.com"
$apiKey = "API_KEY"
$apiSecret = "API_SECRET"
$delegatedFormAccessGroupName = "Users"
 
# Create authorization headers with HelloID API key
$pair = "$apiKey" + ":" + "$apiSecret"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$key = "Basic $base64"
$headers = @{"authorization" = $Key}
# Define specific endpoint URI
if($PortalBaseUrl.EndsWith("/") -eq $false){
    $PortalBaseUrl = $PortalBaseUrl + "/"
}
 
 
 
$variableName = "ADusersDisabledSearchOU"
$variableGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/automation/variables/named/$variableName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
 
    if([string]::IsNullOrEmpty($response.automationVariableGuid)) {
        #Create Variable
        $body = @{
            name = "$variableName";
            value = '[{ "OU": "OU=Disabled,OU=Users,OU=Enyoi,DC=enyoi-media,DC=local"}]';
            secret = "false";
            ItemType = 0;
        }
 
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automation/variable")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $variableGuid = $response.automationVariableGuid
    } else {
        $variableGuid = $response.automationVariableGuid
    }
 
    $variableGuid
} catch {
    $_
}
 
 
 
$taskName = "AD-user-generate-table-disabled"
$taskGetDisabledUsersGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
 
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
 
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
try {
    Hid-Write-Status -Message "SearchBase: $searchOUs" -Event Information
         
    $ous = $searchOUs | ConvertFrom-Json
     
    $users = foreach($item in $ous) {
        Get-ADUser -Filter {Enabled -eq $False} -SearchBase $item.ou -properties *
    }
     
    $users = $users | Sort-Object -Property DisplayName
    $resultCount = @($users).Count
     
    Hid-Write-Status -Message "Result count: $resultCount" -Event Information
    HID-Write-Summary -Message "Result count: $resultCount" -Event Information
     
    if($resultCount -gt 0){
        foreach($user in $users){
            $returnObject = @{SamAccountName=$user.SamAccountName; displayName=$user.displayName; UserPrincipalName=$user.UserPrincipalName; Description=$user.Description; Department=$user.Department; Title=$user.Title;}
            Hid-Add-TaskResult -ResultValue $returnObject
        }
    } else {
        Hid-Add-TaskResult -ResultValue []
    }
} catch {
    HID-Write-Status -Message "Error searching disabled AD users. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Error searching disabled AD users" -Event Failed
     
    Hid-Add-TaskResult -ResultValue []
}
 
'@;
            automationContainer = "1";
            variables = @(@{name = "searchOUs"; value = "{{variable.ADusersDisabledSearchOU}}"; typeConstraint = "string"; secret = "False"})
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetDisabledUsersGuid = $response.automationTaskGuid
 
    } else {
        #Get TaskGUID
        $taskGetDisabledUsersGuid = $response.automationTaskGuid
    }
} catch {
    $_
}
 
$taskGetDisabledUsersGuid
 
 
 
$dataSourceName = "AD-user-generate-table-disabled"
$dataSourceGetDisabledUsersGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
 
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "Department"; type = 0}, @{key = "Description"; type = 0}, @{key = "displayName"; type = 0}, @{key = "SamAccountName"; type = 0}, @{key = "Title"; type = 0}, @{key = "UserPrincipalName"; type = 0});
            automationTaskGUID = "$taskGetDisabledUsersGuid";
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
         
        $dataSourceGetDisabledUsersGuid = $response.dataSourceGUID
    } else {
        #Get DatasourceGUID
        $dataSourceGetDisabledUsersGuid = $response.dataSourceGUID
    }
} catch {}
$dataSourceGetDisabledUsersGuid
 
 
 
 
$formName = "AD Account - Remove inactive account"
$formGuid = ""
 
try
{
    try {
        $uri = ($PortalBaseUrl +"api/v1/forms/$formName")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
    } catch {
        $response = $null
    }
 
    if(([string]::IsNullOrEmpty($response.dynamicFormGUID)) -or ($response.isUpdated -eq $true))
    {
        #Create Dynamic form
        $form = @"
[
  {
    "key": "grid",
    "templateOptions": {
      "label": "Select user account",
      "required": true,
      "grid": {
        "columns": [
          {
            "headerName": "DisplayName",
            "field": "displayName"
          },
          {
            "headerName": "UserPrincipalName",
            "field": "UserPrincipalName"
          },
          {
            "headerName": "Department",
            "field": "Department"
          },
          {
            "headerName": "Title",
            "field": "Title"
          },
          {
            "headerName": "Description",
            "field": "Description"
          }
        ],
        "height": 300,
        "rowSelection": "single"
      },
      "dataSourceConfig": {
        "dataSourceGuid": "$dataSourceGetDisabledUsersGuid",
        "input": {
          "propertyInputs": []
        }
      },
      "useFilter": false
    },
    "type": "grid",
    "summaryVisibility": "Show",
    "requiresTemplateOptions": true
  }
]
"@
 
        $body = @{
            Name = "$formName";
            FormSchema = $form
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/forms")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
 
        $formGuid = $response.dynamicFormGUID
    } else {
        $formGuid = $response.dynamicFormGUID
    }
} catch {
    $_
}
 
$formGuid
 
 
 
 
$delegatedFormAccessGroupGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/groups/$delegatedFormAccessGroupName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
    $delegatedFormAccessGroupGuid = $response.groupGuid
} catch {
    $_
}
 
$delegatedFormAccessGroupGuid
 
 
 
$delegatedFormName = "AD Account - Remove inactive account"
$delegatedFormGuid = ""
 
try {
    try {
        $uri = ($PortalBaseUrl +"api/v1/delegatedforms/$delegatedFormName")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
    } catch {
        $response = $null
    }
 
    if([string]::IsNullOrEmpty($response.delegatedFormGUID)) {
        #Create DelegatedForm
        $body = @{
            name = "$delegatedFormName";
            dynamicFormGUID = "$formGuid";
            isEnabled = "True";
            accessGroups = @("$delegatedFormAccessGroupGuid");
            useFaIcon = "True";
            faIcon = "fa fa-trash-o";
        }   
 
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/delegatedforms")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
 
        $delegatedFormGuid = $response.delegatedFormGUID
    } else {
        #Get delegatedFormGUID
        $delegatedFormGuid = $response.delegatedFormGUID
    }
} catch {
    $_
}
 
$delegatedFormGuid
 
 
 
 
$taskActionName = "AD-user-delete"
$taskActionGuid = ""
 
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskActionName&container=8")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
 
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
 
        $body = @{
            name = "$taskActionName";
            useTemplate = "false";
            powerShellScript = @'
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
'@;
            automationContainer = "8";
            objectGuid = "$delegatedFormGuid";
            variables = @(@{name = "userPrincipalName"; value = "{{form.grid.UserPrincipalName}}"; typeConstraint = "string"; secret = "False"});
        }
        $body = $body | ConvertTo-Json
 
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskActionGuid = $response.automationTaskGuid
 
    } else {
        #Get TaskGUID
        $taskActionGuid = $response.automationTaskGuid
    }
} catch {
    $_
}
 
$taskActionGuid