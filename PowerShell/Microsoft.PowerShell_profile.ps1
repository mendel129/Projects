#https://gist.github.com/mendel129/33bc020d25efd813950eabc56be373a9
if(!(Test-Path $Profile))
{
	New-Item -Path $Profile -Type File -Force
	notepad $Profile
}

set-alias -name npp "C:\Program Files (x86)\Notepad++\notepad++.exe"
set-alias -name edit npp
set-alias -name wireshark "C:\Program Files\Wireshark\Wireshark.exe"
set-alias -name notepad 'C:\Program Files\Notepad++\notepad++.exe'

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

function reload
{
	Start-Process PowerShell -WorkingDirectory $env:USERPROFILE
	exit
	#. $profile
}

function isadmin
 {
 # Returns true/false
   ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
 }
 
 function enable-webcam
{
	#Get-CimInstance Win32_PnPEntity | where PNPDeviceID -eq 'USB\VID_0C45&PID_6717&MI_00\6&65BCF92&0&0000'
	if(isadmin)
	{
		Enable-PnpDevice 'USB\VID_0C45&PID_6717&MI_00\6&65BCF92&0&0000'
	}
	else
	{
		write-error "run me elevated"
	}
}

function disable-webcam
{
	if(isadmin)
	{
		Disable-PnpDevice 'USB\VID_0C45&PID_6717&MI_00\6&65BCF92&0&0000'
	}
	else
	{
		write-error "run me elevated"
	}
}

function get-webcam
{
	If((Get-PnpDevice 'USB\VID_0C45&PID_6717&MI_00\6&65BCF92&0&0000').Status -eq "Error")
	{write-output "webcam disabled"}
	If((Get-PnpDevice 'USB\VID_0C45&PID_6717&MI_00\6&65BCF92&0&0000').Status -eq "OK")
	{write-output "webcam enabled"}
	
}

function sonos-toggle-play
{
	$current=sonos-command "GetTransportInfo"
	if($current -eq "PLAYING"){sonos-command "Pause" | Out-Null}
	else{sonos-command "Play" | Out-Null}
}

function sonos-toggle-mute
{
	[int]$current=sonos-command "GetMute"
	if($current){sonos-command "Unmute" | Out-Null}
	else{sonos-command "Mute" | Out-Null}
}

function sonos-morevolume
{
	[int]$current=sonos-command "GetVolume"
	write-host($current)
	sonos-command "SetVolume" $($current+1) | Out-Null
	$current=sonos-command "GetVolume"
	write-host($current)	
}

function sonos-lessvolume
{
	[int]$current=sonos-command "GetVolume"
	write-host($current)
	sonos-command "SetVolume" $($current-1) | Out-Null
	$current=sonos-command "GetVolume"
	write-host($current)
}

function sonos-command($action, $volume)
{
	#https://github.com/simondettling/Scripts/tree/master/PowerShell/SONOS%20-%20PowerShell%20Controller
	# Enter the IP Adress of your Sonos Component, that is connect via Ethernt. (e.g. Playbar)
	$sonosIP = "192.168.1.xx"

	# Port that is used for communication (Default = 1400)
	$port = 1400

	# Hash table containing SOAP Commands
	$soapCommandTable = @{
		"Pause" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Pause"
			"message" =  '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Pause xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:Pause></s:Body></s:Envelope>'
		}
		"GetTransportInfo" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#GetTransportInfo"
			"message" =  '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:GetTransportInfo xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:GetTransportInfo></s:Body></s:Envelope>'
		}
		"Play" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Play"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><Speed>1</Speed></u:Play></s:Body></s:Envelope>'
		}
		"Next" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Next"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Next xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:Next></s:Body></s:Envelope>'
		}
		"Previous" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Previous"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Previous xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:Previous></s:Body></s:Envelope>'
		}
		"Rewind" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Seek"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Seek xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><Unit>REL_TIME</Unit><Target>00:00:00</Target></u:Seek></s:Body></s:Envelope>'
		}
		"RepeatAll" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#SetPlayMode"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetPlayMode xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><NewPlayMode>REPEAT_ALL</NewPlayMode></u:SetPlayMode></s:Body></s:Envelope>'
		}
		"RepeatOne" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#SetPlayMode"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetPlayMode xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><NewPlayMode>REPEAT_ONE</NewPlayMode></u:SetPlayMode></s:Body></s:Envelope>'
		}
		"RepeatOff" = @{
			"path" = "/MediaRenderer/AVTransport/Control"
			"soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#SetPlayMode"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetPlayMode xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><NewPlayMode>NORMAL</NewPlayMode></u:SetPlayMode></s:Body></s:Envelope>'
		}
		"SetVolume" = @{
			"path" = "/MediaRenderer/RenderingControl/Control"
			"soapAction" = "urn:schemas-upnp-org:service:RenderingControl:1#SetVolume"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetVolume xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>###DESIRED_VOLUME###</DesiredVolume></u:SetVolume></s:Body></s:Envelope>'
		}
		"GetVolume" = @{
			"path" = "/MediaRenderer/RenderingControl/Control"
			"soapAction" = "urn:schemas-upnp-org:service:RenderingControl:1#GetVolume"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:GetVolume xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"><InstanceID>0</InstanceID><Channel>Master</Channel></u:GetVolume></s:Body></s:Envelope>'
		}
		"Mute" = @{
			"path" = "/MediaRenderer/RenderingControl/Control"
			"soapAction" = "urn:schemas-upnp-org:service:RenderingControl:1#SetMute"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetMute xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredMute>1</DesiredMute></u:SetMute></s:Body></s:Envelope>'
		}
		"Unmute" = @{
			"path" = "/MediaRenderer/RenderingControl/Control"
			"soapAction" = "urn:schemas-upnp-org:service:RenderingControl:1#SetMute"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetMute xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredMute>0</DesiredMute></u:SetMute></s:Body></s:Envelope>'
		}
		"Getmute" = @{
			"path" = "/MediaRenderer/RenderingControl/Control"
			"soapAction" = "urn:schemas-upnp-org:service:RenderingControl:1#GetMute"
			"message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:GetMute xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredMute>0</DesiredMute></u:GetMute></s:Body></s:Envelope>'
		}   		
	}	
		
	# Get action from Hash Table, and throw error if it does not exist
	$actionHandler = $soapCommandTable.GetEnumerator() | Where-Object {$_.Key -eq $action}
	If (!$actionHandler) {
		throw "Action '$action' can not be found in Hash Table."
    	}
    
	# Assign values from Hash Table
	$uri = "http://${sonosIP}:$port$($actionHandler.Value.path)"
	$soapAction = $actionHandler.Value.soapAction
	$soapMessage = $actionHandler.Value.message

	# Section for special Actions
	Switch ($action) {
		'setVolume' {
            		If ($volume -gt 60) {
                		# Your neighbors will be thankful ;-)
                		$volume = 60
            		}
            	$soapMessage = $soapMessage.Replace("###DESIRED_VOLUME###", $volume)
        	}
	}

	# Setting Header for WebRequest
	$headers = @{
		'Accept-Encoding' = 'gzip'
		'SOAPACTION' = $soapAction
	}

	# Creating a temporary file
	$tmpFile = [System.IO.Path]::GetTempFileName()

	# Sending WebRequest
	# NOTE: Without the -OutFile Parameter, Invoke-WebRequest throws a ArgumentNullExecption, probably because it can't parse the Response.
	Try {
		Invoke-WebRequest -Uri $uri -Headers $headers -ContentType 'text/xml;' -DisableKeepAlive -Method Post -Body $soapMessage -OutFile $tmpFile
	} Catch {
		Write-Warning -Message $_.Exception.Message
	}
    
	# Get content from temporary file and create XML Object
	If (Test-Path $tmpFile) {
		$responseXml = ConvertTo-Xml -InputObject (Get-Content -Path $tmpFile)
	} Else {
		$responseXml = $false
		Write-Warning -Message "Unable to locate '$tmpFile'"
	}

	# Remove temporary file
	Remove-Item $tmpFile -Force

	#write-host ([xml]$responseXml.Objects.Object.'#text').ChildNodes.Body.GetVolumeResponse.CurrentVolume

	$returnvalue=$responseXml

	Switch ($action) {
		'GetVolume' {
	    		$returnvalue=([xml]$responseXml.Objects.Object.'#text').ChildNodes.Body.GetVolumeResponse.CurrentVolume
		}
		'GetMute' {
    			$returnvalue=([xml]$responseXml.Objects.Object.'#text').ChildNodes.Body.GetMuteResponse.CurrentMute
		}
		'GetTransportInfo' {
    			$returnvalue=([xml]$responseXml.Objects.Object.'#text').ChildNodes.Body.GetTransportInfoResponse.CurrentTransportState
		}
    	}
	
	return $returnvalue
}

#https://www.michev.info/Blog/Post/2140/decode-jwt-access-and-id-tokens-via-powershell
function Parse-JWTtoken {
 
    [cmdletbinding()]
    param([Parameter(Mandatory=$true)][string]$token)
 
    #Validate as per https://tools.ietf.org/html/rfc7519
    #Access and ID tokens are fine, Refresh tokens will not work
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop }
 
    #Header
    $tokenheader = $token.Split(".")[0].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenheader.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenheader += "=" }
    Write-Verbose "Base64 encoded (padded) header:"
    Write-Verbose $tokenheader
    #Convert from Base64 encoded string to PSObject all at once
    Write-Verbose "Decoded header:"
    [System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($tokenheader)) | ConvertFrom-Json | fl | Out-Default
 
    #Payload
    $tokenPayload = $token.Split(".")[1].Replace('-', '+').Replace('_', '/')
    #Fix padding as needed, keep adding "=" until string length modulus 4 reaches 0
    while ($tokenPayload.Length % 4) { Write-Verbose "Invalid length for a Base-64 char array or string, adding ="; $tokenPayload += "=" }
    Write-Verbose "Base64 encoded (padded) payoad:"
    Write-Verbose $tokenPayload
    #Convert to Byte array
    $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
    #Convert to string array
    $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
    Write-Verbose "Decoded array in JSON format:"
    Write-Verbose $tokenArray
    #Convert from JSON to PSObject
    $tokobj = $tokenArray | ConvertFrom-Json
    Write-Verbose "Decoded Payload:"
    
    return $tokobj
}

function decode-base64([string]$a)
{
    $text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($a))
    Write-Output $text	
}

function decompress-string([string]$a)
{   
	$b64 = [System.Convert]::FromBase64String($a)
	$ms = New-Object IO.MemoryStream(,$b64)
	$gzs = New-Object IO.Compression.GzipStream($ms, [IO.Compression.CompressionMode]::Decompress)
	$sr = New-Object IO.StreamReader ($gzs, [Text.Encoding]::UTF8)
	$decoded = $sr.ReadToEnd();
	Write-Host $decoded
}

function compress-string([string]$a)
{   
	$ms = New-Object System.IO.MemoryStream
	$cs = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
	$sw = New-Object System.IO.StreamWriter($cs)
	$sw.Write($a)
	$sw.Close();
	$encoded = [System.Convert]::ToBase64String($ms.ToArray())
	Write-Host $encoded
}

function disable-wsus()
{
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0
	net stop wuauserv
}

function worktime([string]$a)
{
	$firstoftheday=(Get-EventLog System -after (get-date).AddHours(-(get-date).hour) | select -Last 1).TimeGenerated
	$a = $firstoftheday.TimeOfDay 
	write-host "started $a"
	$timeworked = NEW-TIMESPAN -Start (get-date $a.tostring()) -End (get-date)
	$hours = $timeworked.Hours.tostring().trimend()
	$minutes = $timeworked.Minutes.tostring().trimend()
	
	$mintime=8*60+15
	$maxminutes=60+15
	$totalminutes=$($timeworked.Hours*60)+$minutes
	$overtime=$totalminutes-$mintime
	$offset=30
	$percent = ($totalminutes/$mintime)*$offset
	
	$percentstring=""
	while($percent -ge 0){$percentstring += "#";$percent--}
	$percent = $offset-($totalminutes/$mintime)*$offset
	while($percent -ge 0){$percentstring += "-";$percent--}
	
	$overtimepercent = ($overtime / $maxminutes)*$offset
	if($overtime -ge 0){while($overtimepercent -ge 0){$percentstring += "+";$overtimepercent--}}
	$overtimepercent = $offset-($overtime/$maxminutes)*$offset
	if($overtime -ge 0){while($overtimepercent -ge 0){$percentstring += "-";$overtimepercent--}}
	write-host $percentstring
	#only use the min to to pass to something else like | clip
	write-output "min to: $($firstoftheday.AddMinutes($mintime).tostring("HH:mm"))"
	write-output "max to: $($firstoftheday.AddMinutes($mintime+$maxminutes).tostring("HH:mm"))"
	write-output "current time $(get-date -Format "HH:mm")"
}

function keep-awake
{
	$myshell = New-Object -com "Wscript.Shell"
	while(1){
	$myshell.sendkeys("{F15}")
	Start-Sleep -Seconds 240
	}
}
