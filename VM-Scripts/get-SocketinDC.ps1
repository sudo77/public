# Get Socket Info on alls Hosts 
# 

$result = @()
$vmhost = get-vmhost    
foreach ($esxi in $vmhost) {
    $cluster = $esxi | select -expandproperty Parent 
    $vcenter = $esxi.ExtensionData.Client.ServiceUrl.Split('/')[2]

   $HostCPU = $esxi.ExtensionData.Summary.Hardware.NumCpuPkgs
   $HostCPUcore = $esxi.ExtensionData.Summary.Hardware.NumCpuCores/$HostCPU
   $obj = new-object psobject
   $obj | Add-Member -MemberType NoteProperty -Name name -Value $esxi.Name
   $obj | Add-Member -MemberType NoteProperty -Name CPUSocket -Value $HostCPU
   $obj | Add-Member -MemberType NoteProperty -Name Corepersocket -Value $HostCPUcore
   $obj | Add-Member -MemberType NoteProperty -Name Cluster -Value $cluster
   $obj | Add-Member -MemberType NoteProperty -Name vCenter -Value $vcenter

 $result += $obj
}
$result | Format-Table -AutoSize

$result | Export-CSV "c:\temp\vc-Socket-Info.csv" -notypeinformation