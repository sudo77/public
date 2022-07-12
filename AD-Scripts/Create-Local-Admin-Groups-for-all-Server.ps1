#Create AD Group for each Server and ad the Group to each Server as local admin Group
# Sudo77
# 03.12.2019
$ou = [ADSI]"LDAP://OU=_Test,OU=memberserver,OU=test,DC=test,DC=local"  ## OU for ComputerAccount
$ou1 = [ADSI]"LDAP://OU=Server,OU=groups,OU=test,DC=test,DC=local"      ## OU for AD Groups
$groupexists = 0
$groupadded = 0

foreach ($child in $ou.psbase.Children ) { 
	if ($child.ObjectCategory -like '*computer*') { 
		$name = $child.Name 
    Write-Host "Name: $($name)"
		$groupname = "LOC-" + $name + "-ADM"
    Write-Host "GroupName: $($groupname)"
		$groupdescription	= "Local Administrator Group for " + $name
			
    If (![adsi]::Exists("LDAP://CN=$groupname,OU=Server,OU=groups,OU=test,DC=test,DC=local")) {
      $objGroup = $ou1.Create("group", "CN=" + $groupname)
			$objGroup.psbase.InvokeSet("groupType", -2147483648 + 2)
			$objGroup.Put("sAMAccountName", $groupname )
			$objGroup.Put("description", $groupdescription )
			$objGroup.SetInfo()
			$groupadded++
            sleep -Seconds 5
            Add-AdGroupMember -Identity GLO-SERVER-ADM -Members $groupname
			}
	}
}

write-host 'Total Added Groups :'$groupadded
write-host 'Total Exists Groups :'$groupexists
sleep -Seconds 5

### Ad local custom admin group to each server in ou
foreach ($child in $ou.psbase.Children ) { 
	if ($child.ObjectCategory -like '*computer*') { 
		$name = $child.Name 
    Write-Host "Name: $($name)"
		$groupname2 = "LOC-" + $name + "-ADM"
    Write-Host "GroupName: $($groupname)"
		Write-Host "ADing local Admin Group to Server" -ForegroundColor Green
([ADSI]"WinNT://$name/Administrators,group").Add("WinNT://test.local/$groupName2")
sleep -Seconds 5

}
}