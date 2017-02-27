$RPC =Get-Counter "\MSExchange RpcClientAccess\User Count" -computername "exchangea"
$OWA =Get-Counter "\MSExchange OWA\Current Unique Users" -computername "exchangea"
$POP = Get-Counter "\MSExchangePop3(1)\Connections Current" -ComputerName "exchangea"
$IMAP = get-counter "\MSExchangeImap4(1)\Current Connections" -ComputerName "exchangea"
$csa=New-Object PSObject -Property @{
        Server = "exchangea"
        "rpc" = $RPC.CounterSamples[0].CookedValue
        "owa" = $OWA.CounterSamples[0].CookedValue
	"pop" = $POP.CounterSamples[0].CookedValue
	"imap" = $IMAP.CounterSamples[0].CookedValue
      }

$RPC =Get-Counter "\MSExchange RpcClientAccess\User Count" -computername "exchangeb"
$OWA =Get-Counter "\MSExchange OWA\Current Unique Users" -computername "exchangeb"
$POP = Get-Counter “\MSExchangePop3(1)\Connections Current” -ComputerName "exchangeb"
$IMAP = get-counter “\MSExchangeImap4(1)\Current Connections” -ComputerName "exchangeb"
$csb=New-Object PSObject -Property @{
        Server = "exchangeb"
        "rpc" = $RPC.CounterSamples[0].CookedValue
        "owa" = $OWA.CounterSamples[0].CookedValue
	"pop" = $POP.CounterSamples[0].CookedValue
	"imap" = $IMAP.CounterSamples[0].CookedValue
      }

write-host $csa.server", pop:" $csa.pop ", imap" $csa.imap ", owa: " $csa.owa, "rpc: " $csa.rpc
write-host $csb.server", pop:" $csb.pop ", imap" $csb.imap ", owa: " $csb.owa, "rpc: " $csb.rpc
	  
Read-Host "exit"