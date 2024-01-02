Connect-VIServer -Server vc01.fritz.box

#Network List View
$esxName = 'esx01'

$esxcli = Get-EsxCli -VMHost $esxName -V2
$esxcli.network.nic.list.Invoke() |
ForEach-Object -Process {
    $esxcli.network.nic.stats.get.Invoke(@{nicname=$_.Name}) |
    Select @{N='VMHost';E={$esxcli.VMHost.Name}},
        NICName,PacketsReceived,PacketsSent,ReceiveCRCerrors
}

################################

$esxcli.network.nic.list()

#Nic up and Down
$nicName = 'vmnic0'

$esxcli.network.nic.down.Invoke(@{nicname=$nicName})
$esxcli.network.nic.up.Invoke(@{nicname=$nicName})