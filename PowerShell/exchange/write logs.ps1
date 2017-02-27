#write all the importrequests and their report to a file for later reviewing
$reqs=get-mailboximportrequest
foreach($entry in $reqs){$filename=$entry.mailbox.name; $entry | Get-MailboxImportRequestStatistics -IncludeReport | Format-List > $filename".txt"}