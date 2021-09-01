# Zabbix Agent 2 Windows PowerShell installer
Zabbix Agent 2 PowerShell installer.

The script checks if Zabbix Agent 2 is already installed on the client, then asks for some info (prefix, IP/DNS name of Zabbix Server, port to use for inbound connections, metadata for auto-registration rules), then it creates the root dir, the conf file and other things. 

Default config will install Zabbix Agent 2 on C:\Zabbix. To change the directory change the $defpath variable.

The script will ask for a prefix to add before the hostname, that could be useful for multi-site management. Leave it blank to avoid it.
