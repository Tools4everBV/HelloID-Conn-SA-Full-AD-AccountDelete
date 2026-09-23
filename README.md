# HelloID-Conn-SA-Full-AD-AccountDelete

| :information_source: Information |
|:---|
| This repository contains the connector and configuration code only. The implementer is responsible for acquiring the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

## Description

_HelloID-Conn-SA-Full-AD-AccountDelete_ is a delegated form designed for use with HelloID Service Automation (SA). It can be imported into HelloID and customized according to your requirements.

This delegated form searches for disabled Active Directory user accounts and permanently deletes the selected account. The following options are available:

1. Search for disabled Active Directory user accounts
2. Select an account from the search results
3. Confirm and delete the selected account

Deletion is recursive and cannot be undone. Configure the search scope carefully and test the form before making it available to end users.

## Getting started

### Requirements

- **Active Directory access**: The connector requires access to an Active Directory domain with sufficient permissions to search for users and delete objects. A service account with appropriate AD permissions is necessary.
- **HelloID Agent**: A HelloID Agent must be installed and configured to communicate with the Active Directory domain.
- **PowerShell module `ActiveDirectory`**: The HelloID Agent must have PowerShell available with the ActiveDirectory module installed.

### Connection settings

The following user-defined variable is used by the connector:

| Setting                   | Description                                                                                                             | Mandatory |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------- | --------- |
| `AdUsersDisabledSearchOu` | Semicolon-separated (`;`) list of Active Directory OUs used to scope disabled-user search results in the delegated form | Yes       |

The value can contain one or more distinguished names, for example:

```text
OU=Disabled Users,OU=HelloID Training,DC=domain,DC=local;OU=Disabled Users,DC=domain,DC=local
```

The variable can be created and managed using the [HelloID user-defined variables](https://docs.helloid.com/hc/en-us/articles/360014169933-How-to-Create-and-Manage-User-Defined-Variables) documentation.

## Remarks

### User search

- A wildcard search (`*`) returns all disabled users within the configured OUs.
- A partial search matches the `Name`, `DisplayName`, `UserPrincipalName`, and `Mail` attributes.
- Only accounts where `Enabled` is `False` are returned.
- The search scope is limited to the OUs defined in `AdUsersDisabledSearchOu`. Configure this variable carefully to avoid exposing or deleting accounts outside the intended scope.

### Account deletion

The delegated form deletes the selected Active Directory object with `Remove-ADObject -Recursive -Confirm:$false`. The task also writes an audit log entry for successful and failed deletion attempts.

## Development resources

### PowerShell module

This connector uses the ActiveDirectory PowerShell module to search for and delete Active Directory user accounts.

- [ActiveDirectory module documentation](https://learn.microsoft.com/en-us/powershell/module/activedirectory/)

### Cmdlets

The following PowerShell cmdlets are used by the connector:

| Cmdlet            | Description                                                                          |
| ----------------- | ------------------------------------------------------------------------------------ |
| `Get-ADUser`      | Retrieves disabled Active Directory user accounts within the configured search bases |
| `Remove-ADObject` | Permanently removes the selected Active Directory object and its children            |

### Cmdlet documentation

- [Get-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-aduser)
- [Remove-ADObject](https://learn.microsoft.com/en-us/powershell/module/activedirectory/remove-adobject)

## Getting help

For more information on Delegated Forms, refer to the [HelloID Delegated Forms documentation](https://docs.helloid.com/en/service-automation/delegated-forms.html).

## HelloID docs

The official HelloID documentation can be found at [docs.helloid.com](https://docs.helloid.com/).

## Additional links

- [Code](https://github.com/Tools4everBV/HelloID-Conn-SA-Full-AD-AccountDelete)
- [Issues](https://github.com/Tools4everBV/HelloID-Conn-SA-Full-AD-AccountDelete/issues)
- [Pull requests](https://github.com/Tools4everBV/HelloID-Conn-SA-Full-AD-AccountDelete/pulls)
- [Actions](https://github.com/Tools4everBV/HelloID-Conn-SA-Full-AD-AccountDelete/actions)
- [Main branch](https://github.com/Tools4everBV/HelloID-Conn-SA-Full-AD-AccountDelete/tree/main)

> **Information**
> This repository contains connector and configuration code only. The implementer is responsible for acquiring connection details such as username, password, and certificates. Please contact the client's application manager to coordinate the connector requirements.
