Add-Type -AssemblyName System.Windows.Forms
$form = New-Object Windows.Forms.Form

$progressbar1 = New-Object Windows.Forms.Progressbar
$progressbar1.Location = New-Object System.Drawing.Size(10,10) 
$progressbar1.value
$form.Controls.Add($progressbar1)

$drc = $form.ShowDialog()


$jobname = start-job -FilePath .\dothing.ps1 | select name
$runningjob=$true
$i=0
$countaori = 17
$countbori = 17
$counta = $countaori
$countb = $countbori

while ($runningjob) {
	write-host "ehlo"
	Write-Progress -id 1 -Activity "Failovering" -Status "Failovering" -PercentComplete -1
	
	$counta = $counta - 1
	$countb = $countb + 1

	#write-host $counta
	#write-host $countb
	
	$state = (get-job $jobname.name).state
	if($state -eq "running")
	{$runningjob=$true}
	else
	{$runningjob=$false}
	
	#write-host "a"($countaori/$counta)
	#write-host "b"($countbori/$countb)
	
	if(( (($counta)/($countaori))*100 -ge 0 )) 
    { Write-Progress -id 2 -parentid 1 -Activity "den a" -Status "a" -PercentComplete ( (($counta)/($countaori))*100 ) }
	if(( (($countb-$countbori)/($countbori))*100 ) -le 100 )
	{ Write-Progress -id 3 -parentid 1 -Activity "den b" -Status "b" -PercentComplete ( (($countb-$countbori)/($countbori))*100 ) }

    Start-Sleep 1

}

