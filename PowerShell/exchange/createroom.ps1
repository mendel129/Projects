#global vars
$CityArray = "Kontich","Waver","Gent"
$BuildingArrayKontich = "23","20"
$Addresses = @{
	"Kontich" = "straat, 2550 Kontich";
	"Waver"="ERgens 11, 1300 Waver";
	"Gent"="ergens in gent 23, 9000 Gent"
}
#$permissions="ReadItems","EditOwnedItems","DeleteOwnedItems","FolderVisible" #custom folder permissions for coordinators, partners & exceptions ------ probably fail
$simple=$true;#if false: kontich, ask floor and building - if true: other location, only building and name
$exit=$false
$debug=$false;
#$debug=$true;


if($debug)
{
write-host @'
--------------------------------------
---      _      _                  ---
---   __| | ___| |__  _   _  __ _  ---
---  / _` |/ _ \ '_ \| | | |/ _` | ---
--- | (_| |  __/ |_) | |_| | (_| | ---
---  \__,_|\___|_.__/ \__,_|\__, | ---
---                         |___/  ---
--------------------------------------						
'@

write-host "nothing will be created, only simulated"

}

#get valid credentials and connect to exchange
do
{ 
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://exchangeserver/powershell -Credential $cred 
}
while($session -eq $null)
Import-PSSession $session | Out-Null

$list=get-command #test for exchange cmdlets
if($list.Name -contains "Get-Mailboxdatabase")
{write-host "access granted!"}
else
{write-host "not enough credentials - use admin!"
pause
break
}

#get custom attributes: beamer - tv - flipchart - ...
function getcustomattribute
{
	$newarray=@()
	$customs=get-resourceconfig
	$customs=$customs.resourcepropertyschema

	for($i=0;$i -ne $customs.count;$i++)
	{
		$temp=$customs[$i].replace('Room/','')
		$newarray+= $temp
	}

	return $newarray
}

#function to create room
function createroom($Name, $Floor, $Building, $City, $Capacity, $listcustomattributes)
{
	write-host "creating room"
	if($simple)
	{
		write-host "given data: name: $Name - city: $City - capacity: $Capacity - attributes: $listcustomattributes"
	}
	else
	{
		write-host "given data: name:"+ $Name +"floor"+ $Floor +"building" +$Building +"city" +$City +"capacity"+ $Capacity +"attributes" +$listcustomattributes
	}
	
	#get the correct dl - if no building exists, there is no second roomlist!
	if($simple -eq $false)
	{
		$distrigroupsingle = Get-DistributionGroup -RecipientTypeDetails roomlist -identity *$City*  | Where-Object name -like *$Building*
	}
	$distrigroupcity = Get-DistributionGroup -RecipientTypeDetails roomlist -identity "$City"

	#create the names
	if($simple -eq $false)
	{
		$fullname = $City + " - " + $Building + " - " + $Floor + " - " + $Name + " (" + $Capacity + ")"
		$logonname = ($City -replace " ","") + ($Building -replace " ","") + ($Floor -replace " ","") + ($Name -replace " ","")
	}
	else
	{
		$fullname = $City + " - " + $Name + " (" + $Capacity + ")"
		$logonname = ($City -replace " ","")  + ($Name -replace " ","")

	}

	#if logonname > 20 -> shrink!
	do{
		if(($logonname.length -ge 21) -or ($name -eq ""))
		{
			write-host "logonname $logonname can only have 20 characters.."
			if($building -ne $null)
			{
				$temp=($City -replace " ","") + ($Building -replace " ","") + ($Floor -replace " ","")
			}
			else
			{	
				$temp=($City -replace " ","") + ($Floor -replace " ","")
			}
			$temp2=$Name.substring(0,(20-($temp.length)))
			$temp3=$temp+$temp2
			
			write-host $temp.length $temp2.length $temp3.length
			
			write-host "enter new name or use $temp3"
			$answer = read-host "use $temp3 ? y/n"
			if(($answer -eq "y") -or ($answer -eq "yes"))
			{
				$Name=$temp2
			}
			else{
			$Name=read-host "enter new name: (max"(21-($temp.length))"characters)"
			}
			
			if($Building -ne $null)
			{	
				$logonname = ($City -replace " ","") + ($Building -replace " ","") + ($Floor -replace " ","") + ($Name -replace " ","")
			}
			else
			{
				$logonname = ($City -replace " ","")  + ($Name -replace " ","")
			}
		}
		else
		{write-host "done"}
	}while(($logonname.length -ge 21) -or ($Name -eq "") -or ($Name -eq $null))


	write-host "$fullname / $logonname / $Capacity / $listcustomattributes"
	$confirm =  Read-Host "confirm y/n"
	#create the room!
	if( (($confirm -eq "yes") -or ($confirm -eq "y")) -and ($debug -ne $true))
	{
		if(($CityArray -contains $City) -and ($Capacity -match '\d') -and ($Capacity -lt 50))
		{
			if(($city -eq "kontich") -and ($building -eq $null) -and ($Floor -match '^[0-9]$') )
			{
				write-host "fatal error - kontich but no building selected?"
				break;
				
			}	
			else
			{
				#create new mailbox in exchange
				write-host "creating mailbox"
				New-Mailbox -Name $fullname -Alias $logonname -OrganizationalUnit 'contoso.com/corp/Mailbox Accounts/RoomMailboxes' -UserPrincipalName $logonname@contoso.com -SamAccountName $logonname -FirstName $fullname -Initials '' -LastName '' -Database 'Mailbox' -Room
				#enable resource booking attendant
				write-host "enabling autoprocessing"
				#while loop to wait for replication
				while (!((get-calendarprocessing -identity $logonname ).automateprocessing -eq "autoaccept"))
				{
					Set-CalendarProcessing -identity $logonname -AutomateProcessing AutoAccept
					write-host "sleep"
					Start-Sleep -s 1
				}
				#add custom attributes (tv, beamer, ...) and the amount of people who fit in the room to the object
				write-host "adding custrom attributes and capacity"
				Set-Mailbox -Identity $logonname -ResourceCustom $listcustomattributes -ResourceCapacity $Capacity
				#don't remove the subject or comments from the meeting in the room
				write-host "setting options"
				Set-CalendarProcessing -Identity $logonname -DeleteSubject $false -DeleteComments $false
				#add physical location
				write-host "adding location"
				set-mailbox $logonname -Office $Addresses[$City]
				
				#temp hide from address list
				#write-host "hiding!"
				#Set-Mailbox $logonname -HiddenFromAddressListsEnabled $true
				
				#rechten op kalender
				#make partners, coordinators and exceptions author
				write-host "make partners, coordinators and exceptions author"
				add-MailboxFolderPermission -identity $logonname":\Calendar" -User 'partners@cronos.be' -AccessRights "Reviewer"
				add-MailboxFolderPermission -identity $logonname":\Calendar" -User 'Coordinators@cronos.be' -AccessRights "Reviewer"
				add-MailboxFolderPermission -identity $logonname":\Calendar" -User 'Calendar-RoomMailboxes-Exceptions' -AccessRights "Reviewer"
				add-MailboxFolderPermission -identity $logonname":\Calendar" -User 'Calendar-Admin' -AccessRights Owner
				#add partners & coordinators as "in booking" permitted
				write-host "adding bookinpolicies"
				Set-CalendarProcessing -BookInPolicy 'contoso.com/corp/Groups/Security Groups/Partners','contoso.com/corp/Groups/Security Groups/Coordinators','Calendar-RoomMailboxes-Exceptions','calendar-admin' -Identity $logonname
				Set-CalendarProcessing -AllBookInPolicy $false -ForwardRequestsToDelegates $false -Identity $logonname 
				#make officemanagers delegates of the room
				write-host "adding admins as delegate"
				Set-CalendarProcessing -ResourceDelegates 'Calendar-Admin' -Identity $logonname
				#add the room to the correct roomlist(s)
				write-host "adding to outlook roomlists"
				if($building -ne $null)
				{
					write-host "$distrigroupsingle"
					Add-DistributionGroupMember -Identity $distrigroupsingle.name -Member $logonname
				}	
			write-host "$distrigroupcity"				
				Add-DistributionGroupMember -Identity $distrigroupcity.name -Member $logonname
			}
		}
		else
		{
			write-host "wrong call..."
			write-host $city
			write-host $Capacity
			if(($CityArray -contains $City) -and ($Capacity -match '\d') -and ($Capacity -lt 50))
			{	write-host "true"}
			else
			{	write-host "false"}
		}
	}
	elseif($debug)
	{
		#create new mailbox in exchange
		write-host "creating mailbox"
		write-host "New-Mailbox -Name $fullname -Alias $logonname -OrganizationalUnit 'contoso.com/corp/Mailbox Accounts/RoomMailboxes' -UserPrincipalName $logonname@corp.contoso.com -SamAccountName $logonname -FirstName $fullname -Initials '' -LastName '' -Database 'Mailbox' -Room"
		#enable resource booking attendant
		write-host "enabling autoprocessing"
		#while loop to wait for replication
		write-host "Set-CalendarProcessing -identity $logonname -AutomateProcessing AutoAccept"
		#add custom attributes (tv, beamer, ...) and the amount of people who fit in the room to the object
		write-host "adding custrom attributes and capacity"
		write-host "Set-Mailbox -Identity $logonname -ResourceCustom $listcustomattributes -ResourceCapacity $Capacity"
		#don't remove the subject or comments from the meeting in the room
		write-host "setting options"
		write-host "Set-CalendarProcessing -Identity $logonname -DeleteSubject $false -DeleteComments $false"
		#add physical location
		write-host "adding location"
		write-host "set-mailbox $logonname -Office $Addresses[$City]"
		
		#temp hide from address list
		#write-host "hiding!"
		#write-host "Set-Mailbox $logonname -HiddenFromAddressListsEnabled $true"
		
		#make coordinators and exceptions author
		write-host "make partners, coordinators and exceptions author"
		write-host "add-MailboxFolderPermission -identity $logonname':\Calendar' -User 'partners@contoso.com.be' -AccessRights Reviewer"
		write-host "add-MailboxFolderPermission -identity $logonname':\Calendar' -User 'Coordinators@contoso.com.be' -AccessRights Reviewer"
		write-host "add-MailboxFolderPermission -identity $logonname':\Calendar' -User 'Calendar-RoomMailboxes-Exceptions' -AccessRights Reviewer"
		write-host "add-MailboxFolderPermission -identity $logonname':\Calendar' -User 'Calendar-Admin' -AccessRights Owner"
		#add partners & coordinators as "in booking" permitted
		write-host "adding bookinpolicies"
		write-host "Set-CalendarProcessing -BookInPolicy 'contoso.com/corp/Groups/Security Groups/Partners','contoso.com/corp/Groups/Security Groups/Coordinators','Calendar-RoomMailboxes-Exceptions','calendar-admin' -Identity $logonname"
		write-host "Set-CalendarProcessing -AllBookInPolicy $false -ForwardRequestsToDelegates $false -Identity $logonname"
		#make officemanagers delegates of the room
		write-host "adding admins as delegate"
		write-host "Set-CalendarProcessing -ResourceDelegates 'Calendar-Admin' -Identity $logonname"
		#add the room to the correct roomlist(s)
		write-host "adding to outlook roomlists"
		if($building -ne $null)
		{
			write-host "$distrigroupsingle"
			write-host "Add-DistributionGroupMember -Identity $distrigroupsingle.name -Member $logonname"
		}	
		write-host "$distrigroupcity"				
		write-host "Add-DistributionGroupMember -Identity $distrigroupcity.name -Member $logonname"
	}
	else
	{
		"not confirmed"
	}
}

#function to get all the infromation needed for a room
function checkvalues($entry)
{
	write-host "checking input"
	
	if($entry -eq $null) #else ask for entry
	{
		$Name = Read-Host "Name"
	}
	else #read information if overzicht.txt is not found
	{
		write-host "checkvalues for: " + $entry
		$name = $entry
	}
	$var=$Name
	$vars=[regex]::split($var, '- ')
	write-host $vars

	#$entry=""
	#if overzicht.txt is detected, check for content
	if( ($entry -ne $null ) -or ($vars[1] -ne $null) )
	{	
		write-host "automated!"
		$City=$vars[0].TrimEnd()
		if($city -eq "kontich")
		{
			$Building=$vars[1].TrimEnd()
			if($BuildingArrayKontich -contains $Building)
			{
				$vars2=[regex]::split($vars[3], "\)")
				$vars3=[regex]::split($vars2, "\(")
				[int]$Floor=$vars[2].TrimEnd()
				$Name=$vars3[0].TrimEnd()
				[int]$Capacity=$vars3[1].TrimEnd()
			}
			else
			{
				write-host "something is wrong!"
			}
		}
		else
		{
			write-host "automated, not kontich!"
			$vars2=[regex]::split($vars[1], "\)")
			$vars3=[regex]::split($vars2, "\(")
			$Name=$vars3[0].TrimEnd()
			[int]$Capacity=$vars3[1].TrimEnd()
		}
		
		write-host "$City - $Building - $Floor - $Name - $Capacity"
		#if values already exists, process, else, ask
		if(($CityArray -contains $City) -and ($city -ne $null) -and ($Floor -match '^[0-9]$') -and ($Capacity -match '\d') -and ($capacity -ne $null) -and ($Capacity -lt 50))
		{
			write-host "autoprocess"
		}
	}
	else #ask for every value
	{
		write-host "asking values"
		#get city - leuven, kontich, brussel, ...
		do{
			$City = Read-Host "Which city?" $cityarray
			if ($CityArray -contains $City) {} else {write-host "no city!"}
		}
		while(!($CityArray -contains $City))
		$Citytemp=$CityArray -like $City
		$City="$Citytemp"
		if($city -eq "kontich")#if kontich, get building and floor
		{
			do{
				$Building = Read-Host "Which building?" $BuildingArrayKontich
				if ($BuildingArrayKontich -contains $Building) {} else {write-host "not a building"}
			}
			while(!($BuildingArrayKontich -contains $Building))
			$Building = $Building.ToLower()
			#get floor
			do{
				$Floor = Read-Host "Which floor? (0/1/2)"
				if ($Floor -match '^[0-9]$') {} else {write-host "not a floor"}
			}
			while(!($Floor -match '^[0-9]$'))
		}
		
		#get room capacity
		do{
			[int]$Capacity = Read-Host "Room capacity #people?"
			if ($Capacity -match '\d') {if ($Capacity -lt 50) {} else {write-host "you serious..."}} else {write-host "NaN"}
			
		}
		while(!($Capacity -match '\d') -or ($Capacity -gt 50))
	}





	#get attributes - flipchart, beamer, telephone, ...
	$customattributes=getcustomattribute
	write-host "next attributes proposed: $customattributes"
	$listcustomattributes=@()
	foreach($customattribute in $customattributes)
	{
		write-host $customattribute
		$confirm =  Read-Host "y/n"
		if(($confirm -eq "yes") -or ($confirm -eq "y"))
			{$listcustomattributes+=$customattribute}
	}

	write-host "stupido"
	write-host $building 
	($building -ne "")
	($building -ne $null)
	write-host $floor
	($floor -ne "")
	write-host $city
	($city -eq "kontich")
	
	#checking if input is part of kontich, or not
	if( ($building -ne "") -and ($building -ne $null) -and (($floor -ne "") -or ($floor -eq "0")) -and ($city -eq "kontich") )
	{
		write-host "kontich detected!"
		$simple = $false
	}
	elseif (($name -ne "") -and ($city -ne "") )
	{
		write-host "not kontich"
		$simple = $true
	}
	else
	{
		write-host "somethings wrong"
		$simple = "somethingswrong"
	}
	
	if($simple -eq $false)
	{
		write-host "name: $Name - floor: $Floor - building: $Building - city: $City - capacity: $Capacity - attributes: $listcustomattributes"
	}
	else
	{
		write-host "name: $Name - city: $City - capacity: $Capacity - attributes: $listcustomattributes"
	}
	
	write-host "simple: $simple"
	
	if([string]$simple -ne "somethingswrong")
		{createroom $Name  $Floor  $Building  $City  $Capacity  $listcustomattributes}
	else
		{write-host "somethings definately wrong!"}
}


#main function
do{
#process input, if overzicht.txt exists use that, if standardised shortcut, else ask every part of the name




if (test-path overzicht.txt)
{
	$alloverzicht=Get-Content .\overzicht.txt
	write-host "overzicht.txt found"
	write-host $alloverzicht
	$confirm =  Read-Host "use above y/n?"
	
	if(($confirm -eq "yes") -or ($confirm -eq "y"))
	{
		foreach($entry in $alloverzicht)
		{
			if($entry -ne ""){checkvalues $entry}
		}
	}
	else 
	{
		write-host "not using overzicht.txt"
		checkvalues
	}
}
else
{
	write-host "not automated"
	checkvalues
}


$exit=  Read-Host "add another room? y/n"
}
while( ($exit -eq "y") -or ($exit -eq "yes") )


