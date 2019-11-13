# Get Host hardware information
#$vmhost =  "esx01"
#$cluster = "cluster-01"

#Get-VMHost "esx01" |Sort Name |Get-View |
Get-cluster "Cluster01" | Get-VMHost |Sort Name |Get-View |

Select Name, 

@{N=“Type“;E={$_.Hardware.SystemInfo.Vendor+ “ “ + $_.Hardware.SystemInfo.Model}},
@{N="Serial number";E={($_.Hardware.SystemInfo.OtherIdentifyingInfo | where {$_.IdentifierType.Key -eq "ServiceTag"}).IdentifierValue}},
@{N=“CPU“;E={“PROC:“ + $_.Hardware.CpuInfo.NumCpuPackages + “ CORES:“ + $_.Hardware.CpuInfo.NumCpuCores + “ MHZ: “ + [math]::round($_.Hardware.CpuInfo.Hz / 1000000, 0)}},
@{N=“MEM“;E={“” + [math]::round($_.Hardware.MemorySize / 1GB, 0) + “ GB“}},
@{N="BIOS version";E={$_.Hardware.BiosInfo.BiosVersion +  " "+"" + $_.Hardware.BiosInfo.releaseDate }},
@{N="IP Address";E={($_.Config.Network.Vnic | ? {$_.Device -eq "vmk0"}).Spec.Ip.IpAddress}}


#@{N="Bios Date";E={$_.Hardware.BiosInfo.releaseDate}}   #test 
#| Export-Csv c:\temp\HWinfo.csv -noTypeInformation
