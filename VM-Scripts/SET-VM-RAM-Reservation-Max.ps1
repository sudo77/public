
#	Alle VM´s aus einem Cluster
#	Den aktuell konfigurierten RAM komplett reserviert.  
#   Ein Status/Change-Log zentralisiert ablegt
#   Sudo77

################
#Body
#Connect-VIServer -Server $server -Username $username -Password $password
$error.Clear()
$path = "D:\00-Scripts\05-Reporting\88-VMware_Reporting\Ram-Settings"
$patcharchive = "D:\00-Scripts\05-Reporting\88-VMware_Reporting\Ram-Settings\Archive"

$CurrentDate = Get-Date
$CurrentDate = $CurrentDate.ToString('dd-MM-yyyy')


#get VM´s where no RAM Reservation is configuruede
$cluster = get-cluster -name "Clustername"
$vms = $cluster | Get-VM | Where-Object {$_.ExtensionData.ResourceConfig.MemoryAllocation.Reservation -like "0" -or $_.ExtensionData.Config.MemoryReservationLockedToMax -notlike "true"}
$guestConfig = New-Object VMware.Vim.VirtualMachineConfigSpec
$guestConfig.memoryReservationLockedToMax = $True
$report = @()

ForEach ($vm in $vms)
{


if (get-vm $vm | Where-Object {$_.ExtensionData.ResourceConfig.MemoryAllocation.Reservation -eq "0" -or $_.ExtensionData.Config.MemoryReservationLockedToMax -ne "true"})


{
   
   (Get-VM $vm).ExtensionData.ReconfigVM_task($guestConfig)
   Sleep  5
   # create Report    
$vmobj = get-vm $vm
$row = "" | select VM, Cluster, GB, Reservation, ChangeDate
$row.vm = $vmobj.name
$row.Cluster = $vmobj | Get-Cluster | Select -ExpandProperty Name
$row.GB = $vmobj.MemoryGB
$row.Reservation = $vmobj | Get-VMResourceConfiguration | Select -ExpandProperty MemReservationGB 
$row.Changedate =  $CurrentDate
 
$report += $row  


$report |  Export-csv -force  "$path\changeRAMsetting.csv" -UseCulture -NoTypeInformation
$report | Export-csv  "$patcharchive\changeRAMsetting$CurrentDate.csv" -UseCulture -NoTypeInformation
   
   }

   else 
   {
   write-host "nothing to do" -ForegroundColor Yellow
   }


  
      
   }
sleep 5

 $report | Format-Table -AutoSize

 