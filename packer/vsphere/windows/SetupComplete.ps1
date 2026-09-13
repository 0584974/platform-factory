$ErrorActionPreference = 'Stop'

Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="false"}'
winrm set winrm/config/service/auth '@{Basic="false";Kerberos="true";Negotiate="true"}'
Enable-PSRemoting -Force -SkipNetworkProfileCheck

# Install VMware Tools when a Tools ISO is attached as an additional CD-ROM.
$toolsInstaller = Get-Volume | Where-Object DriveType -eq 'CD-ROM' | ForEach-Object {
    $root = "$($_.DriveLetter):\"
    Get-ChildItem -Path $root -Filter setup64.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
} | Select-Object -First 1

if ($toolsInstaller) {
    Start-Process -FilePath $toolsInstaller.FullName -ArgumentList '/S /v "/qn REBOOT=R"' -Wait
}

# Make the guest ready for later Ansible configuration without weakening the
# final security baseline. Ansible uses NTLM initially and then applies the
# hardened Windows role after Terraform clones the template.
New-NetFirewallRule -DisplayName 'WinRM HTTP for provisioning' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5985 -Profile Domain,Private -ErrorAction SilentlyContinue | Out-Null

Write-Host 'Windows bootstrap completed.'
