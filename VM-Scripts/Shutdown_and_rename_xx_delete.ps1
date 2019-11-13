
# Shutdown VM´s from List and rename it like _xx_delete

######################
#$newVmName = ($vm1.name + "_xx_delete")
#Set-VM [vmCurrentName] -Name $newVmName -confirm:$fals
######################

$importDatei = "C:\scripts\VMliste.txt"

$vmlist = Import-Csv -Path $importDatei -Delimiter ";"

foreach ($vm in $vmlist) {

    $vm1 = Get-VM -Name $vm.name -ErrorAction:SilentlyContinue

    if ($vm1.powerstate -eq "poweredon" -and $vm1.Guest.State -eq "Running") {

        $vm1 | Shutdown-VMGuest -Confirm:$false | out-null

        Write-Host $vm1.name  "go offline soft"

        sleep -Seconds 3

    }

    elseif ($vm1.powerstate -eq "poweredon" -and $vm1.Guest.State -eq "NotRunning") {

        $vm1 | where { $_.Guest.State -eq "NotRunning" } | Stop-VM -Confirm:$false | out-null

        Write-Host $vm1.name  "go offline hard"

        sleep -Seconds 3

    }

    else {

        write-host $vm1.name "is already offline" | Format-Table -AutoSize

    }

    Set-VM -VM $vm1 -Name "$($vm1.Name)_xx_delete" -Confirm:$false

}