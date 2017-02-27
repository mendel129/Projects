.'C:\Program Files\Microsoft\Exchange Server\V14\Bin\RemoteExchange.ps1';

Connect-ExchangeServer -auto;

write-host "getting existing move requests..."
#lijst van bestaande move requests
$alreadymoving=Get-MoveRequest | select -expand alias

write-host "getting all users!"
#neem 40 man uit mailservers
#$everyone=Get-Mailbox -ResultSize 40 | where {$_.ServerName -eq "qsfqd" -or $_.ServerName -eq "qsdfdqs"}
$everyone=Get-Mailbox -ResultSize unlimited -filter {(servername -eq "filterserver") -or (servername -eq "filterserver") }
#$everyone=Get-Mailbox -ResultSize 40 -filter {servername -eq "qsfd"}
$movelist=@()
$totalsom=0
$max=500000
$i=0
$timetostop=0

#pak uit deze 40man voor 500gb aan data, momenteel geen exit users, geen mailboxen, en de public serverices mailbox van dqfddqs
ForEach ($SingleMailbox in $everyone) 
{ 
	$i++
	#write-progress -id 1 -activity "find 50gb!" -status "almost there" -percentComplete (($totalsom/$max)*100); 

	$dudename=$SingleMailbox.SamAccountName
	$dudembx = get-mailbox -identity $dudename
	$dudedb = $dudembx.database.name

	if($dudedb -eq "DB" -or $dudedb -eq "Mailbox DB" -or  $dudedb -eq "Public DB")
	{
		#donothing
	}
	else
	{
		if ($alreadymoving -notcontains $SingleMailbox.alias)
		{
			
			if($totalsom -le $max)
			{
				if( (($totalsom/$max)*100) -le 100 )
				{	write-progress -id 1 -activity "find 500gb!" -status "almost there" -percentComplete (($totalsom/$max)*100);	}
				else
 				{	write-progress -id 1 -activity "find 500gb!" -status "almost there" -percentComplete (100);	}

				write-host "adding $SingleMailbox - total: $totalsom mb "
				$MBXstat=Get-MailboxStatistics $SingleMailbox.name
				$size=$MBXstat.totalItemsize.value.toMB()
				$totalsom+=$size
				$samname=$SingleMailbox | Select-Object SamAccountName

				$movelist+=$samname
			}
			else
			{
				$timetostop=1
			}
		}
		else
		{
			#write-host "skipping $SingleMailbox"
		}
	}
	
	$numberofusers=($everyone).count
	write-progress -id 2 -parentId 1 -activity "searching in $numberofusers users" -status "gogogo" -percentComplete ($i/(($everyone).count)*100) 

	if($timetostop)
	{break;}
}
#$movelist
write-host "moving $totalsom gb"
$checkpoint=  Read-Host "confirm yes"
if($checkpoint -eq "yes")
{

foreach ($dude in $movelist)
{
	$dudename=$dude.SamAccountName
	$dudembx = get-mailbox -identity $dudename
	$dudedb = $dudembx.database.name

	$dudedestination=""
	
	#momenteel geen exit users, geen mailboxen, en de public serverices mailbox van gerda
	if($dudedb -eq "Exit users DB" -or $dudedb -eq "Mailbox DB" -or  $dudedb -eq "Public Services DB")
	{
		#donothing
	}
	else
	{
		Switch ($dudedb) {
			"Mailbox DB" 					{$dudedestination = "Mailbox"}
			"Overige DB" 				{$dudedestination = "Overige"}
			"Public Services DB" 				{$dudedestination = "Public Services"}
		}

		#New-MoveRequest -Identity "$dudename" -TargetDatabase "$dudedestination" -DomainController qsfqsdfdqs"
		new-MoveRequest -Identity "$dudename" -TargetDatabase "$dudedestination" -BadItemLimit 1000 -acceptlargedataloss -SuspendWhenReadyToComplete:$true -DomainController "qsdfqsdf"
		

	}
}


$checkpoint=  Read-Host "tis gedaan!"
}