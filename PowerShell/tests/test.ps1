#cd $exscripts
#$jobname = start-job -FilePath .\StartDagServerMaintenance.ps1 -ArgumentList mailboxserver | select name

$serverlist= Get-MailboxServer | where {$_.admindisplayversion -like "*14.3*"}

function dotheaction([string] $servername)
{

	$jobname = start-job -FilePath .\dothing.ps1 | select name
	$runningjob=$true
	$i=0
	$countaori = (Get-MailboxDatabase -Status | where {$_.MountedOnServer -eq "exchangeserverone"}).count
	$countbori = (Get-MailboxDatabase -Status | where {$_.MountedOnServer -eq "exchangeservertwo"}).count

	while ($runningjob) {
		write-host "ehloe"
		Write-Progress -id 1 -Activity "Failovering" -Status "Failovering" -PercentComplete ( (($counta)/($countaori))*100 )
		
		$counta = (Get-MailboxDatabase -Status | where {$_.MountedOnServer -eq "exchangeserverone"}).count
		$countb = (Get-MailboxDatabase -Status | where {$_.MountedOnServer -eq "exchangeservertwo"}).count


		$state = (get-job $jobname.name).state
		if($state -eq "running")
		{$runningjob=$true}
		else
		{$runningjob=$false}

		Write-Progress -id 2 -parentid 1 -Activity "den a" -Status "a" -PercentComplete ( (($counta)/($countaori))*100 )
		write-host ( (($counta)/($countaori))*100 )
		Write-Progress -id 3 -parentid 1 -Activity "den b" -Status "b" -PercentComplete ( (($countb-$countbori)/($countbori))*100 )
		write-host ( (($countb-$countbori)/($countbori))*100 )
		
		$i++
		Start-Sleep 1

	}

}

dotheaction "server"