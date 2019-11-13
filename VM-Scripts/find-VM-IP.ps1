Get-View -ViewType VirtualMachine | ?{ ($_.Guest.Net | %{ $_.IpAddress }) -contains "10.9.1.197" }
