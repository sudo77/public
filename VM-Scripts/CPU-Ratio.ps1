
 $cluster = "CL"

 
$vmhosts= get-cluster $cluster | Get-VMHost 
$vms= get-cluster $cluster | Get-VM
 
$Output=@()
 
ForEach ($vmhost in $vmhosts)
{
 
$vcpus=0
$ratio=$null
$hostthreads=$vmhost.extensiondata.hardware.cpuinfo.numcputhreads
$vms |Where-Object {$_.vmhost -like $vmhost}|ForEach {$vcpus+=$_.numcpu}
if ($vcpus -ne "0") {$ratio= "$("{0:N2}" -f ($vcpus/$hostthreads))" + ":1"}
 
$temp= New-Object psobject
$temp| Add-Member -MemberType Noteproperty "Hostname" -value $vmhost.name
$temp| Add-Member -MemberType Noteproperty "PhysicalThreads" -Value $Hostthreads
$temp| Add-Member -MemberType Noteproperty "vCPUs" -Value $vcpus
$temp| Add-Member -MemberType Noteproperty "Ratio" -Value $ratio
$Output+=$temp
 
}
 
$output
