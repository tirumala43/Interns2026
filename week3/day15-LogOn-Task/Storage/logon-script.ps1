# ================================
# Azure Windows Dev + IIS Setup
# ================================

$logPath = "C:\dev-setup-log.txt"
Start-Transcript -Path $logPath -Append

Write-Host "Starting Automated Setup..."

# --------------------------------
# Install IIS
# --------------------------------
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Dev VM</title>
    <style>
        body { font-family: Arial; background:#f4f6f9; text-align:center; padding:40px; }
        h1 { color:#0078D4; }
        .box { background:white; padding:20px; margin:auto; width:60%; box-shadow:0 0 10px #ccc; border-radius:10px; }
        ul { text-align:left; }
    </style>
</head>
<body>
    <h1>Azure Windows Dev VM</h1>
    <div class="box">
        <h2>Task Details</h2>
        <ul>
            <li>Windows VM Provisioned</li>
            <li>IIS Installed</li>
            <li>VS Code Installed</li>
            <li>Chrome Installed</li>
            <li>Extensions Configured</li>
        </ul>

        <h2>Agenda</h2>
        <ul>
            <li>Infrastructure as Code (ARM)</li>
            <li>Custom Script Extension</li>
            <li>Secure Blob Access via SAS</li>
            <li>Automated Dev Environment</li>
        </ul>
    </div>
    <p>Deployment Successful 🚀</p>
</body>
</html>
"@

Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value $htmlContent -Force

# --------------------------------
# Install Google Chrome (Silent)
# --------------------------------
$chromeInstaller = "$env:TEMP\chrome_installer.exe"
Invoke-WebRequest "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $chromeInstaller
Start-Process -FilePath $chromeInstaller -Args "/silent /install" -Wait

# --------------------------------
# Install VS Code (Silent)
# --------------------------------
$vscodeInstaller = "$env:TEMP\vscode_installer.exe"
Invoke-WebRequest "https://update.code.visualstudio.com/latest/win32-x64-user/stable" -OutFile $vscodeInstaller
Start-Process -FilePath $vscodeInstaller -Args "/verysilent /mergetasks=!runcode" -Wait

Start-Sleep -Seconds 15

$codePath = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd"

# --------------------------------
# Install VS Code Extensions
# --------------------------------
& $codePath --install-extension ms-python.python
& $codePath --install-extension ms-vscode.powershell
& $codePath --install-extension ms-azuretools.vscode-docker
& $codePath --install-extension eamodio.gitlens

# --------------------------------
# Create Logon Scheduled Task
# --------------------------------

$scriptPath = "C:\setup-dev-iis.ps1"

if (!(Test-Path $scriptPath)) {
    Copy-Item $MyInvocation.MyCommand.Path $scriptPath -Force
}

$action = New-ScheduledTaskAction `
  -Execute "PowerShell.exe" `
  -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File $scriptPath"

$trigger = New-ScheduledTaskTrigger -AtLogOn

Register-ScheduledTask `
  -TaskName "DevEnvironmentSetup" `
  -Action $action `
  -Trigger $trigger `
  -User "SYSTEM" `
  -RunLevel Highest `
  -Force

Write-Host "Setup Completed Successfully."
Stop-Transcript