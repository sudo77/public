<#

 .SYNOPSIS
 Optimises Windows Server 2012 R2 Operating Systems running in a Citrix SBC environment.
 
 .DESCRIPTION
 This script disables services, disables scheduled tasks and modifies the registry to optimise system performance on Windows Server 2012 R2 running in a Citrix SBC environment.
 
 .SCRIPT CONSTRUCT
 Script Name   : JGSpiers-WS2012R2Optimisations.ps1
 Author        : George Spiers
 Email         : george@jgspiers.com
 Twitter       : @JGSpiers
 Website       : www.jgspiers.com
 Date Created  : 12.01.2018
 Tested On     : Windows Server 2012 R2 build 9600
 
 .NOTES
 This script makes changes to the system registry and performs other configuration changes. As such a full backup of the machine or snapshot if running in a virtual environment is strongly recommended. Carry out full testing before introducing the optimised image to production.
 You should review ALL optimisations this script makes and determine if they fit in to your environment. Not all optimisations will suit all environemnts.
 To avoid failure, run PowerShell as an administrator before running this script.
 
 .CHANGE LOG (UK date format)
 04.06.18 - Added line to disable the Windows Connection Manager service.
 04.06.18 - Added App Layering question "Will you use this image with App Layering". If yes, two additional services will be disabled.
 30.06.18 - Removed line that disables the Windows Connection Manager service as with this service disabled the network icon appears with a red X, even though it is functional.
 
#>
 
 $Pausefor2 = "Start-Sleep 2"
 $Pausefor5 = "Start-Sleep 5"

 function PVSEventLogRedirect
 { $Global:DriveLetterAnswer = Read-Host "Enter a letter between A and Z"
   $Global:DoesMatch = $DriveLetterAnswer -match "^[a-z]+$" }
  
 #Array of registry objects that will be created
 $CreateRegistry =
 @("DisableTaskOffload DWORD - Disable Task Offloading.","'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' /v DisableTaskOffload /t REG_DWORD /d 0x1 /f"),
  ("HideSCAHealth DWORD - Hide Action Center Icon.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v HideSCAHealth /t REG_DWORD /d 0x1 /f"), #Confirmed that this does hide the Action Center in 2012 R2.
  ("NoRemoteRecursiveEvents DWORD - Turn off change notify events for file and folder changes.","'HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v NoRemoteRecursiveEvents /t REG_DWORD /d 0x1 /f"),
  ("SendAlert DWORD - Do not send Administrative alert during system crash.","'HKLM\SYSTEM\CurrentControlSet\Control\CrashControl' /v SendAlert /t REG_DWORD /d 0x0 /f"),
  ("ServicesPipeTimeout DWORD - Increase services startup timeout from 30 to 45 seconds.","'HKLM\SYSTEM\CurrentControlSet\Control' /v ServicesPipeTimeout /t REG_DWORD /d 0xafc8 /f"),
  ("DisableFirstRunCustomize DWORD - Disable Internet Explorer first-run customise wizard.","'HKLM\SOFTWARE\Policies\Microsoft\Internet Explorer\Main' /v DisableFirstRunCustomize /t REG_DWORD /d 0x1 /f"),
  ("AllowTelemetry DWORD - Disable telemetry.","'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v AllowTelemetry /t REG_DWORD /d 0x0 /f"),
  ("Enabled DWORD - Disable offline files.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\NetCache' /v Enabled /t REG_DWORD /d 0x0 /f"),
  ("Enable REG_SZ - Disable Defrag.","'HKLM\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction' /v Enable /t REG_SZ /d N /f"),
  ("NoAutoUpdate DWORD - Disable Windows Autoupdate.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' /v NoAutoUpdate /t REG_DWORD /d 0x1 /f"),
  ("AUOptions DWORD - Disable Windows Autoupdate.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' /v AUOptions /t REG_DWORD /d 0x1 /f"),
  ("ScheduleInstallDay DWORD - Disable Windows Autoupdate.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' /v ScheduleInstallDay /t REG_DWORD /d 0x0 /f"),
  ("ScheduleInstallTime DWORD - Disable Windows Autoupdate.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' /v ScheduleInstallTime /t REG_DWORD /d 0x3 /f"),
  ("EnableAutoLayout DWORD - Disable Background Layout Service.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OptimalLayout' /v EnableAutoLayout /t REG_DWORD /d 0x0 /f"),
  ("DumpFileSize DWORD - Reduce DedicatedDumpFile DumpFileSize to 2 MB.","'HKLM\SYSTEM\CurrentControlSet\Control\CrashControl' /v DumpFileSize /t REG_DWORD /d 0x2 /f"),
  ("IgnorePagefileSize DWORD - Reduce DedicatedDumpFile DumpFileSize to 2 MB.","'HKLM\SYSTEM\CurrentControlSet\Control\CrashControl' /v IgnorePagefileSize /t REG_DWORD /d 0x1 /f"),
  ("Paths DWORD - Reduce IE Temp File.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Cache\Paths' /v Paths /t REG_DWORD /d 0x4 /f"),
  ("CacheLimit DWORD - Reduce IE Temp File.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Cache\Paths\path1' /v CacheLimit /t REG_DWORD /d 0x100 /f"),
  ("CacheLimit DWORD - Reduce IE Temp File.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Cache\Paths\path2' /v CacheLimit /t REG_DWORD /d 0x100 /f"),
  ("CacheLimit DWORD - Reduce IE Temp File.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Cache\Paths\path3' /v CacheLimit /t REG_DWORD /d 0x100 /f"),
  ("CacheLimit DWORD - Reduce IE Temp File.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Cache\Paths\path4' /v CacheLimit /t REG_DWORD /d 0x100 /f"),
  ("DisableLogonBackgroundImage DWORD - Disable Logon Background Image.","'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' /v DisableLogonBackgroundImage /t REG_DWORD /d 0x1 /f")
 
 #Array of registry objects that will be deleted
 $DeleteRegistry =
 @("StubPath - Themes Setup.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{2C7339CF-2B09-4501-B3F3-F3508C9228ED}' /v StubPath /f"),
  ("StubPath - WinMail.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{44BBA840-CC51-11CF-AAFA-00AA00B6015C}' /v StubPath /f"),
  ("StubPath x64 - WinMail.","'HKLM\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{44BBA840-CC51-11CF-AAFA-00AA00B6015C}' /v StubPath /f"),
  ("StubPath - Enable TLS1.1 and 1.2.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{66C64F22-FC60-4E6C-A6B5-F0D580E680CE}' /v StubPath /f"),
  ("StubPath - Windows Media Player.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{6BF52A52-394A-11d3-B153-00C04F79FAA6}' /v StubPath /f"),
  ("StubPath x64 - Windows Media Player.","'HKLM\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{6BF52A52-394A-11d3-B153-00C04F79FAA6}' /v StubPath /f"),
  ("StubPath - Disable SSL3.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{7D715857-A67C-4C2F-A929-038448584D63}' /v StubPath /f"),
  ("StubPath - Windows Desktop Update.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4340}' /v StubPath /f"),
  ("StubPath - Web Platform Customizations.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{89820200-ECBD-11cf-8B85-00AA005B4383}' /v StubPath /f"),
  ("StubPath - DotNetFrameworks.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}' /v StubPath /f"),
  ("StubPath x64 - DotNetFrameworks.","'HKLM\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\{89B4C1CD-B018-4511-B0A1-5476DBF70820}' /v StubPath /f"),
  ("StubPath - Windows Media Player.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\>{22d6f312-b0f6-11d0-94ab-0080c74c7e95}' /v StubPath /f"),
  ("StubPath x64 - Windows Media Player.","'HKLM\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\>{22d6f312-b0f6-11d0-94ab-0080c74c7e95}' /v StubPath /f"),
  ("StubPath - IE ESC for Admins.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' /v StubPath /f"),
  ("StubPath - IE ESC for Users.","'HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' /v StubPath /f")

 #Array of registry objects that will be modified
 $ModifyRegistry =
 @("DisablePagingExecutive DWORD from 0x0 to 0x1 - Keep drivers and kernel on physical memory.","'HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management' /v DisablePagingExecutive /t REG_DWORD /d 0x1 /f"),
  ("EventLog DWORD from 0x3 to 0x1 - Log print job error notifications in Event Viewer.","'HKLM\SYSTEM\CurrentControlSet\Control\Print\Providers' /v EventLog /t REG_DWORD /d 0x1 /f"),
  ("CrashDumpEnabled DWORD from 0x7 to 0x0 - Disable crash dump creation.","'HKLM\SYSTEM\CurrentControlSet\Control\CrashControl' /v CrashDumpEnabled /t REG_DWORD /d 0x0 /f"),
  ("LogEvent DWORD from 0x1 to 0x0 - Disable system crash logging to Event Log.","'HKLM\SYSTEM\CurrentControlSet\Control\CrashControl' /v LogEvent /t REG_DWORD /d 0x0 /f"),
  ("ErrorMode DWORD from 0x0 to 0x2 - Hide hard error messages.","'HKLM\SYSTEM\CurrentControlSet\Control\Windows' /v ErrorMode /t REG_DWORD /d 0x2 /f"),
  ("MaxSize DWORD from 0x01400000 to 0x00010000 - Reduce Application Event Log size to 64KB","'HKLM\SYSTEM\CurrentControlSet\Services\Eventlog\Application' /v MaxSize /t REG_DWORD /d 0x10000 /f"),
  ("MaxSize DWORD from 0x0140000 to 0x00010000 - Reduce Security Event Log size to 64KB.","'HKLM\SYSTEM\CurrentControlSet\Services\Eventlog\Security' /v MaxSize /t REG_DWORD /d 0x10000 /f"),
  ("MaxSize DWORD from 0x0140000 to 0x00010000 - Reduce System Event Log size to 64KB.","'HKLM\SYSTEM\CurrentControlSet\Services\Eventlog\System' /v MaxSize /t REG_DWORD /d 0x10000 /f"),
  ("ClearPageFileAtShutdown DWORD to 0x0 - Disable clear Page File at shutdown.","'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' /v ClearPageFileAtShutdown /t REG_DWORD /d 0x0 /f"),
  ("DisablePasswordChange DWORD from 0x0 to 0x1 - Disable Machine Account Password Changes.","'HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters' /v DisablePasswordChange /t REG_DWORD /d 0x1 /f"),
  ("PreferredPlan REG_SZ from 381b4222-f694-41f0-9685-ff5bb260df2e to 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c - Changing Power Plan to High Performance.","'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{025A5937-A6BE-4686-A844-36FE4BEC8B6D}' /v PreferredPlan /t REG_SZ /d 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c /f"),
  ("TimeoutValue DWORD from 0x41 to 0xC8 - Increase Disk I/O Timeout to 200 seconds.","'HKLM\SYSTEM\CurrentControlSet\Services\Disk' /v TimeoutValue /t REG_DWORD /d 0xC8 /f")

 #Array of service objects that will be set to disabled
 $Services =
 @("ALG - Application Layer Gateway Service.","ALG"),
  ("AppMgmt - Application Management.","AppMgmt"),
  ("BITS - Background Intelligent Transfer Service.","BITS"),
  ("DPS - Diagnostic Policy Service.","DPS"),
  ("WdiServiceHost - Diagnostic Service Host.","WdiServiceHost"),
  ("WdiSystemHost - Diagnostic System Host.","WdiSystemHost"),
  ("DiagTrack - Diagnostics Tracking Service.","DiagTrack"), #Called Connected User Experiences and Telemetry [Diagnostics Tracking Service] in Windows Server 2016.
  ("EFS - Encrypting File System [EFS].","EFS"),
  ("Eaphost - Extensible Authentication Protocol.","Eaphost"),
  ("FDResPub - Function Discovery Resource Publication.","FDResPub"),
  ("UI0Detect - Interactive Services Detection.","UI0Detect"),
  ("SharedAccess - Internet Connection Sharing [ICS].","SharedAccess"),
  ("iphlpsvc - IP Helper.","iphlpsvc"),
  ("lltdsvc - Link-Layer Topology Discovery Mapper.","lltdsvc"),
  ("wlidsvc - Microsoft Account Sign-in Assistant.","wlidsvc"),
  ("MSiSCSI - Microsoft iSCSI Initiator Service.","MSiSCSI"),
  ("smphost - Microsoft Storage Spaces SMP.","smphost"),
  ("NcbService - Network Connection Broker.","NcbService"),
  ("hkmsvc - Health Key and Certificate Management.","hkmsvc"),
  ("IEEtwCollectorService - Internet Explorer ETW Collector Service.","IEEtwCollectorService"),
  ("NcaSvc - Network Connectivity Assistant.","NcaSvc"),
  ("napagent - Network Access Protection Agent.","napagent"),
  ("WebClient - WebClient.","WebClient"),
  ("defragsvc - Optimize drives.","defragsvc"),
  ("wercplsupport - Problem Reports and Solutions Control Panel.","wercplsupport"),
  ("RasMan - Remote Access Connection Manager.","RasMan"),
  ("SstpSvc - Secure Socket Tunneling Protocol Service.","SstpSvc"),
  ("SNMPTRAP - SNMP Trap.","SNMPTRAP"),
  ("sacsvr - Special Administration Console Helper.","sacsvr"),
  ("svsvc - Spot Verifier.","svsvc"),
  ("SSDPSRV - SSDP Discovery.","SSDPSRV"),
  ("TieringEngineService - Storage Tiers Management.","TieringEngineService"),
  ("SysMain - Superfetch.","SysMain"),
  ("TapiSrv - Telephony.","TapiSrv"),
  ("UALSVC - User Access Logging Service.","UALSVC"),
  ("WerSvc - Windows Error Reporting Service.","WerSvc"),
  ("wuauserv - Windows Update.","wuauserv"),
  ("dot3svc - Wired AutoConfig.","dot3svc")

  #Array of scheduled task objects that will be set to disabled
  $ScheduledTasks = 
  @("'AD RMS Rights Policy Template Management (Manual)'","'\Microsoft\Windows\Active Directory Rights Management Services Client'"),
   ("SmartScreenSpecific","'\Microsoft\Windows\AppID'"),
   ("AitAgent","'\Microsoft\Windows\Application Experience'"), #Named 'Microsoft Compatibility Appraiser' in Windows Server 2016.
   ("ProgramDataUpdater","'\Microsoft\Windows\Application Experience'"),
   ("Proxy","'\Microsoft\Windows\Autochk'"),
   ("ProactiveScan","'\Microsoft\Windows\Chkdsk'"),
   ("Consolidator","'\Microsoft\Windows\Customer Experience Improvement Program'"),
   ("KernelCeipTask","'\Microsoft\Windows\Customer Experience Improvement Program'"),
   ("UsbCeip","'\Microsoft\Windows\Customer Experience Improvement Program'"),
   ("ServerCeipAssistant","'\Microsoft\Windows\Customer Experience Improvement Program\Server'"),
   ("'Data Integrity Scan'","'\Microsoft\Windows\Data Integrity Scan'"),
   ("'Data Integrity Scan for Crash Recovery'","'\Microsoft\Windows\Data Integrity Scan'"),
   ("ScheduledDefrag","'\Microsoft\Windows\Defrag'"),
   ("SilentCleanup","'\Microsoft\Windows\DiskCleanup'"),
   ("'Microsoft-Windows-DiskDiagnosticDataCollector'","'\Microsoft\Windows\DiskDiagnostic'"),
   ("LPRemove","'\Microsoft\Windows\MUI'"),
   ("BindingWorkItemQueueHandler","'\Microsoft\Windows\NetCfg'"),
   ("GatherNetworkInfo","'\Microsoft\Windows\NetTrace'"),
   ("Secure-Boot-Update","'\Microsoft\Windows\PI'"),
   ("Sqm-Tasks","'\Microsoft\Windows\PI'"),
   ("AnalyzeSystem","'\Microsoft\Windows\Power Efficiency Diagnostics'"),
   ("MobilityManager","'\Microsoft\Windows\Ras'"),
   ("RegIdleBackup","'\Microsoft\Windows\Registry'"),
   ("CleanupOldPerfLogs","'\Microsoft\Windows\Server Manager'"),
   ("StartComponentCleanup","'\Microsoft\Windows\Servicing'"),
   ("Configuration","'\Microsoft\Windows\Software Inventory Logging'"),
   ("SpaceAgentTask","'\Microsoft\Windows\SpacePort'"),
   ("'Storage Tiers Management Initialization'","'\Microsoft\Windows\Storage Tiers Management'"),
   ("Tpm-Maintenance","'\Microsoft\Windows\TPM'"),
   ("ResolutionHost","'\Microsoft\Windows\WDI'"),
   ("QueueReporting","'\Microsoft\Windows\Windows Error Reporting'"),
   ("'Scheduled Start'","'\Microsoft\Windows\WindowsUpdate'"),
   ("'Scheduled Start With Network'","'\Microsoft\Windows\WindowsUpdate'"),
   ("'Badge Update'","'\Microsoft\Windows\WS'"),
   ("'License Validation'","'\Microsoft\Windows\WS'"),
   ("'Sync Licenses'","'\Microsoft\Windows\WS'"),
   ("WSRefreshBannedAppsListTask","'\Microsoft\Windows\WS'"),
   ("WSTask","'\Microsoft\Windows\WS'")

 #Check if VMware Tools is installed. If so, ask user if they want to hide the VMware Tools icon from the Notification Area. If yes, add required object to CreateRegistry array.
 if ( Test-Path 'C:\Program Files\\VMware\VMware Tools' )
 { $VMwareAnswer = Read-Host VMware Tools has been detected on your system. Would you like to hide the VMware Tools icon from the Notifications Area for all users? Y/N }
     else { $VMwareAnswer = 'N' }
     while ( "Y","N" -notcontains $VMwareAnswer ) { $VMwareAnswer = Read-Host "Enter Y or N" }
         if ( $VMwareAnswer -eq "Y" ) { $CreateRegistry +=("ShowTray DWORD - Hide VMware Tools tray icon.","'HKLM\SOFTWARE\VMware, Inc.\VMware Tools' /v ShowTray /t REG_DWORD /d 0x0 /f"),
                                                       ("") 
                                     }

 #Check if user is using PVS or MCS. If using PVS, does user want to redirect Event Logs to a persistent drive? If yes, what is the drive letter they will use for the persistent drive? Event Logs will be redirected here.
 $PVSAnswer = Read-Host Are you planning to use this image with PVS? Y/N
  while ( "Y","N" -notcontains $PVSAnswer ) { $PVSAnswer = Read-Host "Enter Y or N" }
   if ( $PVSAnswer -eq "Y" ) { $PVSAnswer = Read-Host Do you want to redirect Event Logs to the persistent drive of each PVS Target Device? Y/N }
         while ( "Y","N" -notcontains $PVSAnswer ) { $PVSAnswer = Read-Host "Enter Y or N" }
           if ( $PVSAnswer -eq "Y" ) { $DriveLetterAnswer = Read-Host What drive letter will you be using for your persistent drive? This is normally D:\. Use letters A-Z }
           if ( $PVSAnswer -eq "N" ) { Write-Host 'OK, Event Logs will be kept on C:\' }
           elseif ( $PVSAnswer -eq "Y" ) { $DoesMatch = $DriveLetterAnswer -match "^[a-z]+$" }
           while (( $DoesMatch -notcontains $null ) -and ( $DoesMatch -notcontains "True" )) { PVSEventLogRedirect }
           if ( $DoesMatch -eq "True" ) { $ModifyRegistry +=("Application REG_EXPAND_SZ from default location to $DriveLetterAnswer - Move Application Event Log from default location to $DriveLetterAnswer","'HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Application' /v File /t REG_EXPAND_SZ /d '$($DriveLetterAnswer):\Event Logs\Application.evtx' /f"),
                                                           ("Security REG_EXPAND_SZ from default location to $DriveLetterAnswer - Move Security Event Log from default location to $DriveLetterAnswer","'HKLM\SYSTEM\CurrentControlSet\Services\EventLog\Security' /v File /t REG_EXPAND_SZ /d '$($DriveLetterAnswer):\Event Logs\Security.evtx' /f"),
                                                           ("System REG_EXPAND_SZ from default location to $DriveLetterAnswer - Move System Event Log from default location to $DriveLetterAnswer","'HKLM\SYSTEM\CurrentControlSet\Services\EventLog\System' /v File /t REG_EXPAND_SZ /d '$($DriveLetterAnswer):\Event Logs\System.evtx' /f"),
                                                           ("")
                                       }

 #Check if user is using App Layering. If using App Layering, the "Microsoft Software Shadow Copy Provider" and "Volume Shadow Copy" services will be disabled.
 $ALAnswer = Read-Host Are you planning to use this image with App Layering? Y/N
  while ( "Y","N" -notcontains $ALAnswer ) { $ALAnswer = Read-Host "Enter Y or N" }
           if ( $ALAnswer -eq "Y" ) { $Services +=("swprv - Microsoft Software Shadow Copy Provider","swprv"),
                                                 ("VSS - Volume Shadow Copy","VSS"),
                                                 ("")
                                       }
          
 $NewCreateRegistry = $CreateRegistry[0..22]
 $NewModifyRegistry = $ModifyRegistry[0..14]
 $NewServices = $Services[0..40] 
 
 Write-Host The following section contains commands that add various registry entires to the system. These optimisations are aimed at improving system performance. Many of these optimisations are the same ones you are offered when running the PVS Target Device Optimization Tool with the exception of HKCU optimisations. Group Policy or Citrix WEM should be used to create HKCU optimisations. -ForeGroundColor Green
 Invoke-Expression $Pausefor5

 #Creating Registry Objects
 foreach ($NewCreateRegistryObject in $NewCreateRegistry) {
 Write-Host Creating registry object $NewCreateRegistryObject[0] -ForegroundColor Cyan
 Invoke-Expression ("reg add " + $NewCreateRegistryObject[1])
 Invoke-Expression $Pausefor2
 }
 
 Write-Host The following section contains commands that remove Active Setup registry entries. These optimisations are aimed at reducing logon times. -ForegroundColor Green
 Invoke-Expression $Pausefor5

 #Deleting Registry Objects
 foreach ($DeleteRegistryObject in $DeleteRegistry) {
 Write-Host Deleting registry object $DeleteRegistryObject[0] -Foregroundcolor Cyan
 Invoke-Expression ("reg delete " + $DeleteRegistryObject[1])
 Invoke-Expression $Pausefor2
 }
 
 Write-Host The following section contains commands that modify various registry entires to the system. These optimisations are aimed at improving system performance. Many of these optimisations are the same ones you are offered when running the PVS Target Device Optimization Tool with the exception of HKCU optimisations. Group Policy or Citrix WEM should be used to create HKCU optimisations. -ForeGroundColor Green
 Invoke-Expression $Pausefor5

 #Modifying Registry Objects
 foreach ($NewModifyRegistryObject in $NewModifyRegistry) {
 Write-Host Modifying $NewModifyRegistryObject[0] -ForegroundColor Cyan
 Invoke-Expression ("reg add " + $NewModifyRegistryObject[1])
 Invoke-Expression $Pausefor2
 }

 Write-Host The following section contains commands that disable services. These optimisations are aimed at reducing system footprint and improving performance.
 Invoke-Expression $Pausefor5
 
 #Disabling Services
 foreach ($ServiceObject in $NewServices) {
 Write-Host Disabling service $ServiceObject[0] -ForegroundColor Cyan
 Invoke-Expression ("Set-Service " + $ServiceObject[1] +  " -StartupType Disabled")
 Invoke-Expression $Pausefor2
 }

 Write-Host The following section contains commands that disable scheduled tasks. These optimisations are aimed at reducing system footprint and improving performance.
 Invoke-Expression $Pausefor5

 #Disabling Scheduled Tasks
 foreach ($ScheduledTaskObject in $ScheduledTasks) {
 Write-Host Disabling scheduled task $ScheduledTaskObject[0] -ForegroundColor Cyan
 Invoke-Expression ("Disable-ScheduledTask -TaskName " + $ScheduledTaskObject[0] + ' -TaskPath ' + $ScheduledTaskObject[1])
 Invoke-Expression $Pausefor2
 }

 Write-Host "All optimisations are complete. Please restart your system." -ForegroundColor Green