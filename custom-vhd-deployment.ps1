#############################################################################################################################################
#                                                                                                                                           #
#                                              Prepare a Windows VHD or VHDX to upload to Azure                                             #
#                                              Simple steps to create and deploy a VM on Azure                                              #        #                                                                                                                                           #
#                                                                                                                                           #
#############################################################################################################################################

# Before you upload a Windows virtual machine (VM) from an on-premise Hyper-v host to Azure, you must prepare the virtual hard disk (VHD or VHDX). 
# Azure supports only generation 1 VMs that are in the VHD file format with a fixed sized disk. 
# The maximum size allowed for the VHD is 1,023 GB. 
# You can convert a generation 1 VM from the VHDX file system to VHD and from a dynamically expanding disk to fixed-sized. 
# But you can't change a VM's generation. 
# If you need to convert your virtual disk to the required format for Azure, use one of the methods in this section. 
# Back up the VM before you run the virtual disk conversion process and make sure that the Windows VHD works correctly on the local server. 
# Resolve any errors within the VM itself before you try to convert or upload it to Azure.
# After you convert the disk, create a VM that uses the converted disk with-in Hyper-V. Start and sign in to the VM to finish preparing the VM for upload
# Following the guide below.

# NOTE** READ the two lines below!
# Do NOT just run this file using PowerShell on the VM you are getting ready for Azure. Open it in PowerShell LSE and run selected commands as you work
# down the document. The commands need to be run and initiated in sequence, if you run the entire script at once it will not work. 

# Convert disk using Hyper-V Manager
1. Open Hyper-V Manager and select server you wish to upload to Azure.
2. go to the settings menu for the VM.
3. On the Locate Virtual Hard Disk screen, locate and select your virtual disk.
4. On the Choose Action screen select Convert and Next.
5. Select VHD and then click Next (select VHD even if it's already .vhd)
6. If you need to convert from a dynamically expanding disk, select Fixed size and then click Next. (Select fixed regardless)
7. Select a local path to save the exported .VHD.
8. Click Finish.
9. Wait for the export to complete.
10. Create a new VM and select "Use an existing disk" select the exported .VHD and create the VM.
11. Start the VM and follow the required steps below.

# Convert an existing disk using PowerShell instead of the above export option.
# Locate the .VHD / .VHDX file of your server, copy it to a new location and run the command below. You must run as Administrator.
Convert-VHD –Path c:\test\MY-VM.vhdx –DestinationPath c:\test\MY-NEW-VM.vhd -VHDType Fixed
# Or
Convert-VHD –Path c:\test\MY-VM.vhd –DestinationPath c:\test\MY-NEW-VM.vhd -VHDType Fixed
# Convert the .VHD / .VHDX regardless - Even of the disk is .vhd already. It MUST be "fixed"

# Additional drives attached to the server? Ie; D:\ E:\ etc?
# Convert the disks as stated above and upload using Microsoft Azure Storage Explorer, be sure to select "Page Blogs" prior to uploading.
# Create a Disk from the uploaded .VHD file and attach to the VM as a data disk once the VM has booted in Azure. 
# The link to the Storage Explorer is at the bottom of this file.

# Once the disk has converted, create a NEW VM with the converted disk to ensure it boots and continue with the below changes
# READ THE WHOLE FILE!

# Set Windows configurations for Azure
# Remove the WinHTTP proxy
cmd.exe
netsh winhttp reset proxy
exit

# Set the disk SAN policy to Onlineall
cmd.exe
diskpart 
san policy=onlineall
exit 

# Once more - Select the PowerShell commands and execute them individually. Do NOT run the entire script at once. 

# Set Coordinated Universal Time (UTC) time for Windows and the startup type of the Windows Time (w32time) service to Automatically start.
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -name "RealTimeIsUniversal" -Value 1 -Type DWord -force
Set-Service -Name w32time -StartupType Automatic

# Set the power profile to the High Performance
powercfg /setactive SCHEME_MIN

# Make sure that the environmental variables TEMP and TMP are set to their default values
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -name "TEMP" -Value "%SystemRoot%\TEMP" -Type ExpandString -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -name "TMP" -Value "%SystemRoot%\TEMP" -Type ExpandString -force

# Check the Windows services
# Make sure that each of the following Windows services is set to the Windows default values. 
# These are the minimum numbers of services that must be set up to make sure that the VM has connectivity. 
# To reset the startup settings, run the following commands
Set-Service -Name bfe -StartupType Automatic
Set-Service -Name dhcp -StartupType Automatic
Set-Service -Name dnscache -StartupType Automatic
Set-Service -Name IKEEXT -StartupType Automatic
Set-Service -Name iphlpsvc -StartupType Automatic
Set-Service -Name netlogon -StartupType Manual
Set-Service -Name netman -StartupType Manual
Set-Service -Name nsi -StartupType Automatic
Set-Service -Name termService -StartupType Manual
Set-Service -Name MpsSvc -StartupType Automatic
Set-Service -Name RemoteRegistry -StartupType Automatic

# Update Remote Desktop registry settings
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDenyTSConnections" -Value 0 -Type DWord -force

# The RDP port is set up correctly (Default port 3389)
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "PortNumber" -Value 3389 -Type DWord -force

# The listener is listening in every network interface
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "LanAdapter" -Value 0 -Type DWord -force

# Configure the Network Level Authentication mode for the RDP connections
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "SecurityLayer" -Value 1 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "fAllowSecProtocolNegotiation" -Value 1 -Type DWord -force

# Set the keep-alive value
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "KeepAliveEnable" -Value 1  -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "KeepAliveInterval" -Value 1  -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "KeepAliveTimeout" -Value 1 -Type DWord -force

# Reconnect
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDisableAutoReconnect" -Value 0 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "fInheritReconnectSame" -Value 1 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "fReconnectSame" -Value 0 -Type DWord -force

# Limit the number of concurrent connections
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "MaxInstanceCount" -Value 4294967295 -Type DWord -force

# If there are any self-signed certificates tied to the RDP listener, remove them
Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "SSLCertificateSHA1Hash" -force

# Configure Windows Firewall rules
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Enable-PSRemoting -force
Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Enabled True

# Enable the following firewall rules to allow the RDP traffic
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Enabled True

# Enable the File and Printer Sharing rule so that the VM can respond to a ping command inside the Virtual Network
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True

# Verify VM is healthy, secure, and accessible with RDP
cmd.exe
Chkdsk /f
exit

# Set the Boot Configuration Data (BCD) settings
cmd.exe
bcdedit /set {bootmgr} integrityservices enable
bcdedit /set {default} device partition=C:
bcdedit /set {default} integrityservices enable
bcdedit /set {default} recoveryenabled Off
bcdedit /set {default} osdevice partition=C:
bcdedit /set {default} bootstatuspolicy IgnoreAllFailures

# Enable Serial Console Feature
bcdedit /set {bootmgr} displaybootmenu yes
bcdedit /set {bootmgr} timeout 5
bcdedit /set {bootmgr} bootems yes
bcdedit /ems {current} ON
bcdedit /emssettings EMSPORT:1 EMSBAUDRATE:115200
exit

# The Dump log can be helpful in troubleshooting Windows crash issues. Enable the Dump log collection
# Setup the Guest OS to collect a kernel dump on an OS crash event
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -name CrashDumpEnabled -Type DWord -force -Value 2
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -name DumpFile -Type ExpandString -force -Value "%SystemRoot%\MEMORY.DMP"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -name NMICrashDump -Type DWord -force -Value 1

#Setup the Guest OS to collect user mode dumps on a service crash event
$key = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if ((Test-Path -Path $key) -eq $false) {(New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' -Name LocalDumps)}
New-ItemProperty -Path $key -name DumpFolder -Type ExpandString -force -Value "c:\CrashDumps"
New-ItemProperty -Path $key -name CrashCount -Type DWord -force -Value 10
New-ItemProperty -Path $key -name DumpType -Type DWord -force -Value 2
Set-Service -Name WerSvc -StartupType Manual

# Verify that the Windows Management Instrumentations repository is consistent. To perform this, run the following command
winmgmt /verifyrepository

# Ensure no other applications are using the RDP port (3389) - We are going to change the default port used once the VM is in Azure.
netstat -anob

************************************************************ NOTE IMPORTANT ******************************************************************
# Things to do now to ensure the VM boots when you upload it to Azure - I have come across various issuse that prevented the .VHD from booting 
# and or allowing access to the serial console. 

1. Make sure you have patched the server as the .VHD depends on various security patches and updates that can prevent the .VHD from booting!!
2. Run a windows update and let it update everything.
3. Install the Azure VM Agent : Download the agent from: http://go.microsoft.com/fwlink/?LinkID=394789&clcid=0x409
   - https://azure.microsoft.com/en-us/blog/vm-agent-and-extensions-part-1/
   - https://azure.microsoft.com/en-us/blog/vm-agent-and-extensions-part-2/
4. Change the following registry values as the very last step, these steps ensure the server boots correctly when you create the image in Azure.
   - HKEY_LOCAL_MACHINE\Select\Current - From 1 to 2
   - HKEY_LOCAL_MACHINE\Select\Default - From 1 to 2        
   - HKEY_LOCAL_MACHINE\Select\Failed - From 0 to 1
   - HKEY_LOCAL_MACHINE\Select\LastKnownGood - From 2 to 3
5. Shutdown the server.

# The above registry changes need to be changed prior to exporting or converting your .VHD / VHDX, these settings allow the image to be created and the VM 
# to boot correctly when creating a VM from your custom Image.

# Create the custom Image.
1. Upload the .VHD file to your storage container using the Storage Explorer, again ensure "Page Blobs" is selected or it won't work
2. Once uploaded, go to the Azure portal and select Images from the resources menu.
3. Click create image, select your uploaded .VHD from the drop down options (You can copy the link from Storage Explorer)
4. Let the Image create.
5. Go back to the main Images section and click "Create VM"

# Another thing to note is custom firewall rules set in Local Security Policies. If you have anything configured here you should disable these
# rules until you have the VM booted in Azure. You can setup the rules again once you have access to the server. Some firewall rules will block
# your connection to the server once you have spent the time creating it in Azure. 

# You can disable the rules in the SAC console but some configured security rules will prevent all traffic entering the server. Just a thought! 

route -f
reg delete HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\PersistentRoutes /va /f

************************************************************ THINGS TODO *******************************************************************
# After the VM is created in Azure, we recommend that you put the pagefile on the ”Temporal drive” volume to improve performance. 
# You can set up this as follows:
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -name "PagingFiles" -Value "D:\pagefile" -Type MultiString -force

# If there’s any data disk that is attached to the VM, the Temporal drive volume's drive letter is typically "D." 
# This designation could be different, depending on the number of available drives and the settings that you make.

# Change the RDP port, this is mainly aimed at security. You can simply add a rule from the Network Security Groups on the portal to allow access
# Paste this line first
Write-host "What Port would you like to set for RDP: "-NoNewline;$RDPPort = Read-Host
 
# Paste these two lines next
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-TCP\" -Name PortNumber -Value $RDPPort
New-NetFirewallRule -DisplayName "RDP HighPort" -Direction Inbound –LocalPort $RDPPort -Protocol TCP -Action Allow

# Confirm the rules are in place 
Write-host "port number is $RDPPORT" 
Write-host "Launch RDP with IP:$RDPORT or cmdline MSTSC /V [ip]:$RDPORT"

# RDP Connection Issues when VM has been created, cun this command client side and ensure all patches are installed
# The above command gets rid of the CredSSP issue when tring to login to a VM
# https://blogs.technet.microsoft.com/mckittrick/unable-to-rdp-to-virtual-machine-credssp-encryption-oracle-remediation/
REG  ADD HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters\ /v AllowEncryptionOracle /t REG_DWORD /d 2

# All done you should now have a .VHD file ready to upload to Azure!
# I would recommend using Microsoft Azure Storage Explorer to upload the file to your Stoarg Containers as you can select "Page Blob" prior
# to selecting the .VHD you have just created. The .VHD needs to be uploaded using the Page BLob option or it will not work.
https://docs.microsoft.com/en-us/azure/vs-azure-tools-storage-manage-with-storage-explorer?tabs=windows 

# Go ahead andupload your .VHD to Azure. Good Luck!

************************************************************ A FEW EXTRAS *******************************************************************
# Just a few extra links that may help out or at least speed up your deployment. 
https://docs.microsoft.com/en-us/powershell/module/hyper-v/convert-vhd?view=win10-ps
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/multiple-nics
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/change-drive-letter
https://azure.microsoft.com/en-us/blog/vm-agent-and-extensions-part-1/
https://azure.microsoft.com/en-us/blog/vm-agent-and-extensions-part-2/
