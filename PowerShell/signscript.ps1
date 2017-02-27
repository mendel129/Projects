$cert = Get-ChildItem cert:\CurrentUser\My -CodeSigningCert
Set-AuthenticodeSignature -Certificate $cert -FilePath C:\users\account\Desktop\lockoutstatus.ps1