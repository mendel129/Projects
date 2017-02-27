write-host "ehlo -sleeping"
for($i=0; $i -ne 17;$i++)
{
	$var=10-$i
	write-host "sleeping for" $var
	sleep 1
}