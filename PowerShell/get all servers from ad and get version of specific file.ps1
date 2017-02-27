#get a list from ad with all windows server 2003 and 2003 r2 machines
$list= get-ADComputer -Filter {OperatingSystem -Like "Windows Server*2003*"}
#intantiate an empty array
$hashlist=@{}
$admin=get-credential
#connect to each computer, get the file, and select it's version
foreach($computer in $list){
	$answer = Get-WMIObject -Computer $computer.DNSHostName -credential $admin -Query "SELECT * FROM CIM_DataFile WHERE Drive ='C:' AND Path='\\windows\\system32\\' AND FileName='crypt32' AND Extension='dll'" | select Version
	#create a hashlist
	$hashlist[$computer]=$answer
}
$hashlist | export-csv export.csv

#rewrite the hashlist for proper export to a csv-file (otherwise, it's almost not readable for humans :-)
$collection = @()
foreach ($key in $hashlist.Keys) {
   $store = "" | select "OS","count"
   $store.OS = "$Key"
   $store.count = $hashlist.$Key
   $collection += $store
}
$collection | Export-Csv "OSCount2.csv" -NoTypeInformation