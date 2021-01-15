#https://gist.github.com/mendel129/33bc020d25efd813950eabc56be373a9
if(!(Test-Path $Profile))
{
	New-Item -Path $Profile -Type File -Force
	notepad $Profile
}

set-alias -name npp "C:\Program Files (x86)\Notepad++\notepad++.exe"
set-alias -name edit npp
set-alias -name wireshark "C:\Program Files\Wireshark\Wireshark.exe"

$profilepath = $env:USERPROFILE

function edit-profile {edit $profile}

function get-uptime {
	$lastBootTime=(Get-WmiObject win32_operatingsystem | select csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}).LastBootUpTime
	$uptime = (Get-Date) - $lastBootTime
	write-output "uptime: $uptime - last boot: $lastBootTime"
}

function elevate {
	$file, [string]$arguments = $args;
	$psi = new-object System.Diagnostics.ProcessStartInfo $file;
	$psi.Arguments = $arguments;
	$psi.Verb = "runas";
	$psi.WorkingDirectory = get-location;
	[System.Diagnostics.Process]::Start($psi);
}

function reboot {
	shutdown -r -t 0
}

function set-staticip {
	netsh interface ipv4 set address name="DOCK" static 192.168.1.10 255.255.255.0
}

function set-dynamicip {
	netsh interface ipv4 set address name="DOCK" source=dhcp
}
