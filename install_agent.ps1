<#

Script di installazione di Zabbix Agent 2
Versione 2.2

#>

# Auto-admin restart
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

### .conf file creator
function CompileFile($ip, $port, $hn, $metadata, $defpath, $confpath, $confname) {
    Add-Content -Path "$defpath\$confname" -Value "##### Zabbix Configuration file from Powershell #####"
    Add-Content -Path "$defpath\$confname" -Value "## Passive check related ##"
    Add-Content -Path "$defpath\$confname" -Value "Server=$ip"
    Add-Content -Path "$defpath\$confname" -Value "ListenPort=$port"
    Add-Content -Path "$defpath\$confname" -Value ""
    Add-Content -Path "$defpath\$confname" -Value ""
    Add-Content -Path "$defpath\$confname" -Value "## Active check related ##"
    Add-Content -Path "$defpath\$confname" -Value "ServerActive=$ip"
    Add-Content -Path "$defpath\$confname" -Value "Hostname=$hn"
    if ($metadata -ne "") {Add-Content -Path "$defpath\$confname" -Value "HostMetadata=$metadata"}
    Add-Content -Path "$defpath\$confname" -Value ""
    Add-Content -Path "$defpath\$confname" -Value ""
    Add-Content -Path "$defpath\$confname" -Value "## Other params ##"
    Add-Content -Path "$defpath\$confname" -Value "UnsafeUserParameters=1"
    Add-Content -Path "$defpath\$confname" -Value "Include=$confpath\*.conf"
    Add-Content -Path "$defpath\$confname" -Value "LogFile=$defpath\zabbix_agent2.log"
    Add-Content -Path "$defpath\$confname" -Value ""
    Add-Content -Path "$defpath\$confname" -Value ""
}

Clear-Host
Write-Host -ForegroundColor Yellow "Zabbix Agent 2 configuration creator v1.0" 
Write-Host ""



###################  If service already exists  ###################

If (Get-Service "Zabbix Agent 2" -ErrorAction SilentlyContinue) {

    if ((Get-Service "Zabbix Agent 2").Status -eq 'Running') {

        Write-Host "Zabbix agent already installed and running! Stopping and uninstalling..."

        try {
            Start-Process C:\Zabbix\zabbix_agent2.exe -Verb runAs -ArgumentList "--config C:\Zabbix\zabbix_agent2.conf --stop" -Wait
            Write-Host "Agent stopped successfully!"
            Start-Sleep -Seconds 2
            Start-Process C:\Zabbix\zabbix_agent2.exe -Verb runAs -ArgumentList "--config C:\Zabbix\zabbix_agent2.conf --uninstall" -Wait
            Write-Host "Agent uninstalled successfully!"
        } catch {Write-Host -ForegroundColor Red "cannot stop or uninstall agent service!"}

        if ((Test-Path -Path "C:\Zabbix") -eq $True) {Remove-Item -Path C:\Zabbix -Recurse}

        Write-Host "Previous agent uninstalled. Relaunch the script in order to install agent."
        Read-Host
        exit

    } else {
        
        Write-Host "Zabbix agent already installed! Uninstalling..."
        Write-Host ""
        Write-Host ""

        try {
            Start-Process C:\Zabbix\zabbix_agent2.exe -Verb runAs -ArgumentList "--config C:\Zabbix\zabbix_agent2.conf --uninstall" -Wait
            Write-Host "Agent uninstall successfully!"
        } catch {Write-Host -ForegroundColor Red "cannot uninstall agent service!"}

        Start-Sleep -Seconds 2

        if ((Test-Path -Path "C:\Zabbix") -eq $True) {Remove-Item -Path C:\Zabbix -Recurse}

        Write-Host "Previous agent uninstalled. Relaunch the script in order to install agent."
        Read-Host
        exit
    }

} else {
    Write-Host "no Zabbix agent installed found, beginning installation..."
    Write-Host ""
    Write-Host "---------------------------------------------------------------------------------"
    Write-Host ""
}



###################  Create folders and copy files  ###################

$prefix = Read-Host "Client name prefix [same name of the hostgroup, leave blank for 'ISVico']"
if ($prefix -eq "") {$prefix = "ISVico"}
$hn = "$prefix $env:computername"

$ip = Read-Host "IP address of server/proxy"

$port = Read-Host "Port of server/proxy [default 10050]"
if ($port -eq "") {$port = 10050}

Write-Host ""
Write-Host "Host metadata need to be the same for all agents to connect automatically to a Autoreg rule on server side."
Write-Host "(to register the agent to the IS server use 'IS-Sedi-Vico')"
$metadata = Read-Host "Host metadata (IS-...)"


$defpath = "C:\Zabbix"
$confname = "zabbix_agent2.conf"
$scriptpath = "$defpath\scripts"
$confpath = "$defpath\customconfigs"


### Make dir in C:\
if ((Test-Path $defpath) -eq $false) {
    New-Item "$defpath" -ItemType "directory" | Out-Null
}

### Make empty text file .CONF
$l = Test-Path "$defpath\$confname"
if ($l -eq $True) {
    do {
        $Prompt = Read-Host "$confname already exists! Want to replace it? [y/n]"
        Switch ($Prompt) {
            y {
                Remove-Item -Path "$defpath\$confname"
                New-Item "$defpath" -ItemType file -Name "$confname" | Out-Null
                CompileFile $ip $port $hn $metadata $defpath $confpath $confname
            }
            n {
                Write-Host "exiting..."
                Read-Host
                exit
            }
        }
    } while ($Prompt -notmatch "[YN]")
}
if ($l -eq $False) {
    New-Item "$defpath" -ItemType file -Name "$confname" | Out-Null
    CompileFile $ip $port $hn $metadata $defpath $confpath $confname
}


### Make folders in subdir
if ((Test-Path "$scriptpath") -eq $False) {
    
    New-Item "$scriptpath" -ItemType "directory" | Out-Null
}


### Make folder for custom configs in subdir
if ((Test-Path "$confpath") -eq $False) {

    New-Item "$confpath" -ItemType "directory" | Out-Null
    New-Item "$confpath\place_custom_parameters_here.conf" -ItemType "file" | Out-Null
}


### Copy CMDs for service control
if ((Test-Path "$defpath\commands") -eq $False) {

    Copy-Item -Path "$PSScriptRoot\commands" -Destination $defpath -Recurse
}


### Copy .exe file
$exename = "zabbix_agent2.exe"
if ((Test-Path "$defpath\$exename") -eq $False) {

    if ((Test-Path "$PSScriptRoot\zabbix_agent2.exe") -eq $True) {

        Copy-Item -Path "$PSScriptRoot\zabbix_agent2.exe" -Destination "$defpath"
    }
}



###################  Firewall rule  ###################

Write-Host ""
$k = Get-NetFirewallRule -DisplayName 'Zabbix Agent TCP inbound connection' 2> $null
if ($k) { 
    Write-Host "Firewall rule already exists."
}
else {
    do {
        $Prompt = Read-Host "Create firewall rule for inbound connection on TCP 10050? [y/n]"
        Switch ($Prompt) {
            y {
                try {
                    New-NetFirewallRule -DisplayName "Zabbix Agent TCP inbound connection" -Direction Inbound -LocalPort $port -Protocol TCP -Action Allow
                }
                catch {
                    Write-Host -ForegroundColor Red "Error opening port! Check it manually!"
                }
            }
            n {
                Write-Host "No firewall rule added."
            }
        }
        Write-Host ""
    } while ($Prompt -notmatch "[YN]")
}

Start-Sleep -Seconds 2



###################  Install and run the service  ###################

try {
    Start-Process C:\Zabbix\zabbix_agent2.exe -Verb runAs -ArgumentList "--config C:\Zabbix\zabbix_agent2.conf --install" -Wait
    Write-Host "Agent installed successfully!"
    SC.exe failure "Zabbix Agent 2" reset= 60000 actions= restart/30000/restart/60000/run/90000 command= "C:\Zabbix\commands\cmd_run.cmd"
    } catch {Write-Host -ForegroundColor Red "cannot install agent service!"}

Start-Sleep -Seconds 2

try {
    Start-Process C:\Zabbix\zabbix_agent2.exe -Verb runAs -ArgumentList "--config C:\Zabbix\zabbix_agent2.conf --start" -Wait
    Write-Host "Agent started successfully!"
    } catch {Write-Host -ForegroundColor Red "cannot start agent service!"}



Write-Host "Finished! Run with cmds in C:\Zabbix\commands folder."
Write-Host "Press enter key to exit..."
Read-Host
exit

