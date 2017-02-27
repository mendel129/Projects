Function Get-LockedOutLocation 
{ 
<# 
.SYNOPSIS 
    This function will locate the computer that processed a failed user logon attempt which caused the user account to become locked out. 
 
.DESCRIPTION 
    This function will locate the computer that processed a failed user logon attempt which caused the user account to become locked out.  
    The locked out location is found by querying the PDC Emulator for locked out events (4740).   
    The function will display the BadPasswordTime attribute on all of the domain controllers to add in further troubleshooting. 
 
.EXAMPLE 
    PS C:\>Get-LockedOutLocation -Identity Joe.Davis 
 
 
    This example will find the locked out location for Joe Davis. 
.NOTE 
    This function is only compatible with an environment where the domain controller with the PDCe role to be running Windows Server 2008 SP2 and up.   
    The script is also dependent the ActiveDirectory PowerShell module, which requires the AD Web services to be running on at least one domain controller. 
    Author:Jason Walker 
    Last Modified: 3/20/2013 
#> 
    [CmdletBinding()] 
 
    Param( 
      [Parameter(Mandatory=$True)] 
      [String]$Identity       
    ) 
 
    Begin 
    {  
        $DCCounter = 0  
        $LockedOutStats = @()    
                 
        Try 
        { 
            Import-Module ActiveDirectory -ErrorAction Stop 
        } 
        Catch 
        { 
           Write-Warning $_ 
           Break 
        } 
    }#end begin 
    Process 
    { 
         
        #Get all domain controllers in domain 
        $DomainControllers = Get-ADDomainController -Filter * 
        $PDCEmulator = ($DomainControllers | Where-Object {$_.OperationMasterRoles -contains "PDCEmulator"}) 
         
        Write-Verbose "Finding the domain controllers in the domain" 
        Foreach($DC in $DomainControllers) 
        { 
            $DCCounter++ 
            Write-Progress -Activity "Contacting DCs for lockout info" -Status "Querying $($DC.Hostname)" -PercentComplete (($DCCounter/$DomainControllers.Count) * 100) 
            Try 
            { 
                $UserInfo = Get-ADUser -Identity $Identity  -Server $DC.Hostname -Properties AccountLockoutTime,LastBadPasswordAttempt,BadPwdCount,LockedOut -ErrorAction Stop 
            } 
            Catch 
            { 
                Write-Warning $_ 
                Continue 
            } 
            If($UserInfo.LastBadPasswordAttempt) 
            {     
                $LockedOutStats += New-Object -TypeName PSObject -Property @{ 
                        Name                   = $UserInfo.SamAccountName 
                        SID                    = $UserInfo.SID.Value 
                        LockedOut              = $UserInfo.LockedOut 
                        BadPwdCount            = $UserInfo.BadPwdCount 
                        BadPasswordTime        = $UserInfo.BadPasswordTime             
                        DomainController       = $DC.Hostname 
                        AccountLockoutTime     = $UserInfo.AccountLockoutTime 
                        LastBadPasswordAttempt = ($UserInfo.LastBadPasswordAttempt).ToLocalTime() 
                    }           
            }#end if 
        }#end foreach DCs 
        $LockedOutStats | Format-Table -Property Name,LockedOut,DomainController,BadPwdCount,AccountLockoutTime,LastBadPasswordAttempt -AutoSize 
 
        #Get User Info 
        Try 
        {   
           Write-Verbose "Querying event log on $($PDCEmulator.HostName)" 
           $LockedOutEvents = Get-WinEvent -ComputerName $PDCEmulator.HostName -FilterHashtable @{LogName='Security';Id=4740} -ErrorAction Stop | Sort-Object -Property TimeCreated -Descending 
        } 
        Catch  
        {           
           Write-Warning $_ 
           Continue 
        }#end catch      
                                  
        Foreach($Event in $LockedOutEvents) 
        {    

           If($Event | Where {$_.Properties[2].value -match $UserInfo.SID.Value}) 
           {  
               
              $var=$Event | Select-Object -Property @( 
                @{Label = 'User';               Expression = {$_.Properties[0].Value}} 
                @{Label = 'DomainController';   Expression = {$_.MachineName}} 
                @{Label = 'EventId';            Expression = {$_.Id}} 
                @{Label = 'LockedOutTimeStamp'; Expression = {$_.TimeCreated}} 
                @{Label = 'Message';            Expression = {$_.Message -split "`r" | Select -First 1}} 
                @{Label = 'LockedOutLocation';  Expression = {$_.Properties[1].Value}} 
              ) 

			$var | ft *
            }#end ifevent 
             
       }#end foreach lockedout event 
        
    }#end process 
    
}#end function

do{
Get-LockedOutLocation
$exit=read-host "exit yes/no"
}
while(($exit -eq "yes") -or ($exit -eq "y"))
# SIG # Begin signature block
# MIIIwQYJKoZIhvcNAQcCoIIIsjCCCK4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZTqON2i+IF2DpsG1U9P2WH7/
# 8uegggY+MIIGOjCCBSKgAwIBAgIKJqqmEwAAAAABTzANBgkqhkiG9w0BAQsFADA+
# MRIwEAYKCZImiZPyLGQBGRYCYmUxFjAUBgoJkiaJk/IsZAEZFgZpY29ub3MxEDAO
# BgNVBAMTB2Nyb2NlcnQwHhcNMTMwNjI3MDgzMjM3WhcNMTQwNjI3MDgzMjM3WjB4
# MRIwEAYKCZImiZPyLGQBGRYCYmUxFjAUBgoJkiaJk/IsZAEZFgZpY29ub3MxDzAN
# BgNVBAsTBkljb25vczEOMAwGA1UECxMFQWRtaW4xFjAUBgNVBAsTDURvbWFpbiBB
# ZG1pbnMxETAPBgNVBAMTCGFkbWluZHNsMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAloZjCOx8QEts/oxTm4zLBBqaboxhhJoaHAy7ru+MRrkwoNzL6a5D
# 5qSUL4yiFIdTX7VBJs4z9MWBJoTNEEkXOfG6fhJ7lFBzDDeE41dsI8rbBmjm2qFL
# uSnce47GE0a7EIvhjL/TVOfOV3AQzwkcjQv1yh4SFIOrM1kfhN3B+541nFR445Ws
# 3Vt91BZovnraTBL+JxW+HkmZXH01R5RAyDNCAQrO8KU0XxdBwdBSwFKpkpGyWSoX
# xnHbAU/Tn+5x83hkk/A9vbBzm0h+4bzOCflENiYPCpmGA+/UBYx/wVNVS8Q3q5yT
# uN7xJQBXCCwnx7UMxjVD0vPpHsuNBeHttQIDAQABo4IC/jCCAvowCwYDVR0PBAQD
# AgeAMD0GCSsGAQQBgjcVBwQwMC4GJisGAQQBgjcVCISlw3eCkO5ohYGLK4WxoWjk
# tU2BeIPs3i2GsJNbAgFkAgEDMB0GA1UdDgQWBBRmPlvz00R6q7jheuWpUtWCGFIN
# fDAfBgNVHSMEGDAWgBSzif2SfHiq49XEntW/P40pTb/MezCBxwYDVR0fBIG/MIG8
# MIG5oIG2oIGzhoGwbGRhcDovLy9DTj1jcm9jZXJ0LENOPVdTMDgtTlBTLUNBLENO
# PUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1D
# b25maWd1cmF0aW9uLERDPWljb25vcyxEQz1iZT9jZXJ0aWZpY2F0ZVJldm9jYXRp
# b25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwggE/
# BggrBgEFBQcBAQSCATEwggEtMIGkBggrBgEFBQcwAoaBl2xkYXA6Ly8vQ049Y3Jv
# Y2VydCxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vydmlj
# ZXMsQ049Q29uZmlndXJhdGlvbixEQz1pY29ub3MsREM9YmU/Y0FDZXJ0aWZpY2F0
# ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwVQYIKwYB
# BQUHMAKGSWh0dHA6Ly93czA4LW5wcy1jYS5pY29ub3MuYmUvQ2VydEVucm9sbC9X
# UzA4LU5QUy1DQS5pY29ub3MuYmVfY3JvY2VydC5jcnQwLQYIKwYBBQUHMAGGIWh0
# dHA6Ly93czA4LW5wcy1jYS5pY29ub3MuYmUvb2NzcDATBgNVHSUEDDAKBggrBgEF
# BQcDAzAbBgkrBgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMC0GA1UdEQQmMCSgIgYK
# KwYBBAGCNxQCA6AUDBJhZG1pbmRzbEBpY29ub3MuYmUwDQYJKoZIhvcNAQELBQAD
# ggEBAB2uGqbRl4L8GrlDQIEfeN3nkXtQBgGLdHVFMBxoqFtx2AJja9iqDEeQbooS
# RLvkHA3mBEEDsgiLJaNQ5AiHWST6Gs/EGZfu47k4gPr+5SqSNXm6Ne5moN2pYR4/
# eGjb/niCRjLaPOeHvQ7JIi2qYKrZVuGqFb6FQ/dYIjYSjkIGxeie+Yvr9MxW3Mqi
# JqOH6nFFvtxnvAgBde5PC+nuGk6dpOYykZZBqPPSKI/ByFZDrI+sjzr0w9Bsxqgy
# xvXxtCriStFOx2Uj0SR9YKd0GN5do2hykmpEihJClE+XR+K78zb/fCQQlP+iU25U
# sXyywQ+gHBQ1iEJtwPIC3Ey2KfQxggHtMIIB6QIBATBMMD4xEjAQBgoJkiaJk/Is
# ZAEZFgJiZTEWMBQGCgmSJomT8ixkARkWBmljb25vczEQMA4GA1UEAxMHY3JvY2Vy
# dAIKJqqmEwAAAAABTzAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAA
# oQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4w
# DAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUTkfL25jmnLx5jOwctk9sfhsy
# dOIwDQYJKoZIhvcNAQEBBQAEggEAPKmnJi8HOPhd+ZTm2xJZDeNEy5LhPiA20bQG
# i6MgY3mZZyGOmbcc995epr6cnVC3foK0XZekhnWFX91jTLSqzfg6Yna+qe8jy/H4
# V1xZlM+CyptiYDl6HrQuoFkYUSPd/bhxoPH22b/e0Bz8P0xPxUo3W8tFw7PV4Goo
# qpdonC95NaiWe/yCPRW/aG0SquHnkqs13HAGfqKOxWCb5WThj41DSVpUY0Wn0hkp
# 04AdW/bw96IsSjkx3mo/iEelk061ysbCR9Vq57GxaUNM2imwFSHA3TEuwZCjMFWW
# 0+J2oi7ioJpFcjgvwsWQ5oMtD5afnGR8ZsBg/POBXqrOqhEuRg==
# SIG # End signature block
