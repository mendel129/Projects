function eentjemeer()
{
	if($global:i -le 100)
	{
		$progressbar1.value = $global:i
		write-host $global:i
		$global:i=$global:i+10
		$Form.Refresh()
	}
}

Add-Type -AssemblyName System.Windows.Forms
$Form = New-Object Windows.Forms.Form

$progressbar1 = New-Object Windows.Forms.Progressbar
$progressbar1.Location = New-Object System.Drawing.Size(10,50) 
$progressbar1.size = new-object System.Drawing.Size(250,25)
$progressbar1.Maximum = 100
$progressbar1.Minimum = 0
$global:i=0
$progressbar1.value = $global:i
$Form.Controls.Add($progressbar1)


$btnConfirm = new-object System.Windows.Forms.Button
$btnConfirm.Location = new-object System.Drawing.Size(120,10)
$btnConfirm.Size = new-object System.Drawing.Size(100,30)

$btnConfirm.Text = "Start Progress"
$btnConfirm.add_click({ eentjemeer })
$Form.Controls.Add($btnConfirm)

$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()