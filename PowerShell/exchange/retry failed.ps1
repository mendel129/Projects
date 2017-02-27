#modify amount of accepted failed items
Get-MailboxImportRequest -status failed | set-mailboximportrequest -baditemlimit 5
#resume from where left
get-mailboximportrequest -status failed | resume-mailboximportrequest


#pretty much the same
$allfailed = get-mailboximportrequest -status failed
foreach($failed in $allfailed)
{
	$path = $failed.filepath
	$target = $failed.targetmailboxidentity
	$retrycount = "5"
	write-host "new-mailboximportrequest -mailbox '$target' -filepath '$path' -baditemlimit $retrycount"
	new-mailboximportrequest -mailbox $target -filepath $path -baditemlimit $retrycount
}