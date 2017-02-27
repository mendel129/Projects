#get all mailboxes
$thelist = get-mailbox *

#get name from the request en create a new wone
$failed = get-mailboximportrequest -status failed
foreach($mailbox in $failed)
{
	$name=	$mailbox.MAILBOX.name
	new-mailboxexportrequest -mailbox $name -FilePath \\123.123.123.123\exports\$name.pst
}
#can be subsituted by
Get-MailboxImportRequest -status failed | set-mailboximportrequest -baditemlimit 5
get-mailboximportrequest -status failed | resume-mailboximportrequest



#create new exportrequests
$thelist = get-mailbox *
foreach($mailbox in $thelist)
{
	new-mailboxexportrequest -mailbox $mailbox -FilePath \\123.123.123.123\exports\$mailbox.pst
}



#get raw percentage of completion (3 times the same)
(get-mailboxexportrequest | Get-MailboxExportRequestStatistics | where {$_.status -eq "completed"}).count/$thelist.count
(Get-MailboxImportRequest -status completed | Get-MailboxExportRequestStatistics).count/$thelist.count
(get-mailboxexportrequest | Get-MailboxExportRequestStatistics | where {$_.status -eq "completed"}).count/(get-mailbox).count


#show some statistics about speed
get-mailboxexportrequest  | Get-MailboxExportRequestStatistics | where {$_.status -eq "inprogress"} | ft *perminute*,sourcealias,*percent*
get-mailboxexportrequest -status inprogress | Get-MailboxExportRequestStatistics | ft *perminute*,sourcealias,*percent*
Get-MailboxExportRequest | Get-MailboxExportRequestStatistics | ft sourcealias,*perminute*,*complete*