$Credential1=$(Get-Credential) #server1
$Credential2=$(Get-Credential) #server2

Set-Item WSMan:\localhost\Client\TrustedHosts -Value "35.180.137.149, 52.47.149.134" -force

$Session1 = New-PSSession -ComputerName 35.180.137.149 -Credential $Credential1
$Session2 = New-PSSession -ComputerName 52.47.149.134 -Credential $Credential2

Invoke-Command -Session $Session1 -ScriptBlock {

Write-Host "Connected to server #1"

Uninstall-WindowsFeature -name Web-Server -IncludeManagementTools 

Restart-Computer -force

Write-Host "Server #1 is restarting"
}

Invoke-Command -Session $Session2 -ScriptBlock {

Write-Host "Connected to server #2"

Uninstall-WindowsFeature -name Web-Server -IncludeManagementTools 

Restart-Computer -force

Write-Host "Server #2 is restarting"
}

Sleep -s 100

$Session1 = New-PSSession -ComputerName 35.180.137.149 -Credential $Credential1
$Session2 = New-PSSession -ComputerName 52.47.149.134 -Credential $Credential2

Invoke-Command -Session $Session1 {Install-WindowsFeature -name Web-Server -IncludeManagementTools}
Invoke-Command -Session $Session2 {Install-WindowsFeature -name Web-Server -IncludeManagementTools}

Write-Host "New IISs are ready"



