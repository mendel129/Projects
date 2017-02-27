#set some variables
$pathkruibeke= "\\localhost\exports\ "
$pathlier= "\\localhost\exports\lier\ "
$allmbx = get-mailbox *
$allmbxstats = $allmbx | get-mailboxstatistics
$imports = get-mailboximportrequest
$failedreqs = $imports | where { $_.status -eq "failed"}

$allemptymbx = $allmbxstats | where { $_.itemcount -le 5}

#list all imports in progress
$importnamearray = @()
foreach($import in $imports)
{
	$importnamearray += $import.mailbox.name
}

#list all users with empty mailbox
$todolist = @()
foreach($emptymbx in $allemptymbx)
{
	if($importnamearray -contains $emptymbx.displayname)
	 {}
	 else
	 {
		$todolist += $emptymbx.displayname
	 }
}

#list all psts
$dir = get-childitem -path $pathkruibeke
$allpstskruibeke = @()
foreach($entry in $dir)
{
	$allpstskruibeke+=$entry.name
}
$dir = get-childitem -path $pathlier
$allpstslier = @()
foreach($entry in $dir)
{
	$allpstslier+=$entry.name
}



#if not in progress, and emtpy mailbox, try to find the pst in the list of psts's, otherwise ask manual location of pst
foreach($usertodo in $todolist)
{
	write-host "user to do: $usertodo"
	
	if($importnamearray -contains $usertodo)
	{	write-host "$usertodo - already working" }
	else
	{
		if($allpstslier -contains ($usertodo+".pst"))
			{ 
				$path = $pathlier + $usertodo +".pst"
				write-host "$usertodo - pst found! @ $path"
				write-host "new-mailboximportrequest -mailbox '$usertodo' -filepath $path"
				$var=read-host "sure?"
				if($var -eq "y")
				{
					new-mailboximportrequest -mailbox $usertodo -filepath $path
				}
			}
		elseif($allpstskruibeke -contains ($usertodo+".pst"))
			{ 
				$path = $pathkruibeke + $usertodo +".pst"
				write-host "$usertodo - pst found! @ $path"
				write-host "new-mailboximportrequest -mailbox '$usertodo' -filepath $path"
				$var=read-host "sure?"
				if($var -eq "y")
				{
					new-mailboximportrequest -mailbox $usertodo -filepath $path
				}
			}
		else
			{
				write-host "$usertodo - no pst"
				$path = read-host "\\localhost\exports\ "
				write-host "new-mailboximportrequest -mailbox '$usertodo' -filepath $path"
				$var=read-host "sure?"
				if($var -eq "y")
				{
					new-mailboximportrequest -mailbox $usertodo -filepath $path
				}
			}
	}
}