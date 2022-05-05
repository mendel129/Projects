function test-mendel {
	$root=[adsi]"LDAP://somedomaincontroller:636"
	$Searcher = New-Object System.DirectoryServices.DirectorySearcher($root)
	$Searcher.filter = "(&(objectCategory=person)(objectClass=user)(msNPAllowDialin=TRUE)(sAMAccountName=somename))"
	$User = $Searcher.findall()
	If($User.count -eq 0)
	{write-output 'not fixed yet'}
}

function get-forest-functionallevel{
	switch (([adsi]"LDAP://CN=Partitions,$(([adsi]("LDAP://RootDSE")).configurationNamingContext)").'msDS-Behavior-Version') {
		0 {'DS_BEHAVIOR_WIN2000'}
		1 {'DS_BEHAVIOR_WIN2003_WITH_MIXED_DOMAINS'}
		2 {'DS_BEHAVIOR_WIN2003'}
		3 {'DS_BEHAVIOR_WIN2008'}
		4 {'DS_BEHAVIOR_WIN2008R2'}
		5 {'DS_BEHAVIOR_WIN2012'}
		6 {'DS_BEHAVIOR_WIN2012R2'}
	}
}

function recurse-group([string]$dn)
{
	$allmembers = @()
	
	$root="LDAP://somedomaincontroller:636"
	$obj=[adsi]"$root/$dn"
	# write-host "connected to $($obj.distinguishedName)"
	# write-host $obj.member
	foreach($member in $obj.member)
	{
		$memdn=[adsi]"$root/$member"
		
		if($memdn.class -eq "group")
		{
			# write-host "found nested group"
			$allmembers+=recurse-group $memdn.distinguishedName
		}
		else
		{
			# write-host "adding $($memdn.distinguishedName)"
			$allmembers+=$memdn.distinguishedName
		}
	}
	
	return $allmembers
}

function log-groups {
	$groups = @()
	$reportdate=Get-Date -Format "yyyyMMdd_HHmmss"
	
	$root="LDAP://somedomaincontroller:636"
	$path=[adsi]"$root/OU=groups,OU=someou,DC=somedomain,DC=sometld"
	$Searcher = New-Object System.DirectoryServices.DirectorySearcher($path)
	$Searcher.filter = "(&(cn=prefix*)(objectClass=group))"
	$groups = $Searcher.findall()
	
	foreach($group in $groups)
	{
		$groupdn=$group.properties.distinguishedname
		#write-host "looking for $groupdn"
		$groupusers = recurse-group $groupdn§
		foreach($groupuser in $groupusers)
		{
			$Object = New-Object PSObject -Property @{
				userdn = $groupuser.tostring()
				GroupName = $groupdn.substring(0)
				DateTime = $reportdate
			}
			
			# $groupuser | Add-Member -MemberType NoteProperty -Name GroupName -Value $groupdn
			# $groupuser | Add-Member -MemberType NoteProperty -Name DateTime -Value $reportdate
		
			$groups += $Object
		}
	}
	
	$previousdata=import-csv -Delimiter ";" ./loggedgroups.csv
	$nextdata=$previousdata+$groups
	$nextdata | export-csv  -Delimiter ";" ./loggedgroups.csv
	
		
}
