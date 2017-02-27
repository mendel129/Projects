#finds all registered SCP's in domain
Get-ADObject -SearchBase "cn=configuration,dc=corp,dc=contoso,dc=com" -Filter "objectclass -eq 'serviceconnectionpoint'"