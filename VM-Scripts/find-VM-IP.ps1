#Find VM with IP
Get-View -ViewType VirtualMachine | ?{ ($_.Guest.Net | %{ $_.IpAddress }) -contains "10.10.150.197" }
