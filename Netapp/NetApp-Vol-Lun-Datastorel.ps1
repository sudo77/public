clear

#####
$datastoreName = "TEST-06"
$volLunSize = 1
#####
$NACL =  "192.168.178.131"
$Nuser ="admin"
$Npw = "Netapp1!"
#####

$aktDate = Date
$volName = "vol_$datastoreName".Replace("-","_")
#$volName.Replace("-","_")
$lunName =  "lun_$datastoreName".Replace("-","_")
#$lunName.Replace("-","_")

$volMaxSize = [Math]::Round($volLunSize * 1 + (($volLunSize * 1)  * 10/100))
$VolNr = $datastoreName.Split("-")[1]
#$volMaxSize = [Math]::Round($volLunSize * 1024 + (($volLunSize * 1024)  * 10/100))

# NetApp Cluster 

$ControllerPassword = ConvertTo-SecureString -String $Npw -AsPlainText -force
$ControllerCredential = New-Object System.Management.Automation.PsCredential("admin",$ControllerPassword)	
Connect-NcController  $NACL -Credential $ControllerCredential

########### End setting SVM and AGGR Name ###########
if ([int]$VolNr % 2 -eq 0) 
{
	$svm = "SVM2"
    $agg = "agg_data02"
    $igrName = "InitGroup2"
}
else
{
	$svm = "SVM1"
    $agg = "agg_data01"
    $igrName = "InitGroup1"
}

$svm
$agg 

########### Start creating the new volume ###########
New-NcVol -VserverContext $svm -Aggregate $agg -Name $volName -size ("$volLunSize" + "g") -SpaceReserve none -SnapshotPolicy none -SnapshotReserve 0 -JunctionPath $null -ErrorAction stop -Verbose

#Get-NcVol $volName | Enable-NcSis
Get-NcVol $volName | Set-NcVolOption -Key fractional_reserve -Value 0
Get-NcVol $volName | Set-NcVolOption -Key read-realloc -Value on
Get-NcVol $volName | Set-NcVolOption -Key no_atime_update -Value on

#Get-NcVol $volName | Set-NcSis -Policy $dedupol
Get-NcVol $volName | Set-NcVolAutosize -Enabled -MaximumSize ("$volMaxSize" + "g") -IncrementSize 10g
########### Start creating the new volume ###########

########### Start creating the new lun ###########
#$lunName = $VolName.Replace('v','L')
$lpa = ("/vol/" + $volName + "/" + $lunName)

New-NcLun -VserverContext $svm -Path $lpa -size ("$volLunSize" + "g") -Unreserved -OsType vmware -ErrorAction stop -Verbose
$lunID = $VolNr
Get-NcLun -Volume $volName | Add-NcLunMap -Path ($lpa) -InitiatorGroup $igrName -Id $lunID	-ErrorAction stop -Verbose




