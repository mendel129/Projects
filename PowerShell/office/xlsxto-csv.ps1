#https://stackoverflow.com/questions/67200337/converting-an-excel-file-into-csv-file-in-powershell
$names=get-childitem $pwd | select name

foreach($name in $names)
{
	$excel = New-Object -ComObject Excel.Application
	$WB =  $excel.Workbooks.Open("$pwd/$($name.name)")
	$WB.SaveAs("$pwd\$($name.name).csv",6)
	$excel.Quit()
}
