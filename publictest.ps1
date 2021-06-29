$dclist=(Get-ADDomainController -Filter {IsReadOnly -eq $false}).Name -like "muc*"
#$userlist = Import-Csv "C:\00-Scripts\19.06fix.csv" -Delimiter ";"
$Userlist = Get-ADUser schmidsebas
#$userlist = Import-Csv "C:\00-Scripts\userliste.txt"


#$userlist = Get-ADUser -Filter {UserPrincipalName -like "*@baywa.de"}  | where { $_.DistinguishedName -notlike "*OU=SpezialUser*" -and $_.Name -notlike "x_*"}


$result = @()

FOREACH ($user in $userlist)   #userlist.sam bei Liste

{
$obj = get-aduser $user -Properties *


$stamplistallDC = @()
$nstamplist = @()

FOREACH ($dc in $dclist)
    {

##############################################
$stamp = Get-ADUser $obj -Properties * -Server $dc | select -expandProperty lastLogon  ###nur zur berrech
$stamplistallDC += $stamp 
}

$laststamplistallDC = $stamplistallDC | Measure-Object -Maximum
$hstamp = $laststamplistallDC.Maximum
#Converts the stamp into a date
$lastlogon = [datetime]::FromFileTime($hstamp) 
##############################################





##report
$info = "" | Select Username,Enabled, UPN, Created, PasswordLastSet,LastBadPasswordAttempt, LastLogonfromallDC,Expiredate
#$obj = get-aduser $user -Properties *
#$upn = $user.value
#$obj = Get-ADUser -Filter "UserPrincipalName -eq '$upn'" 
$lastLogonTimestamp = get-aduser $obj -server $dc -Properties Lastlogontimestamp | Select-Object -property @{n='LastLogonTimestamp';e={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}
$info.Username = $obj.name
$info.enabled = get-aduser $obj -Properties enabled | Select -ExpandProperty enabled
$info.upn = $obj.UserPrincipalName
$info.PasswordLastSet = $obj | Select-Object -Property * | select -ExpandProperty PasswordLastSet
$info.LastBadPasswordAttempt = get-aduser $obj  -properties * | Select-Object -ExpandProperty  LastBadPasswordAttempt
$info.created = get-aduser $obj -Properties whencreated | Select -ExpandProperty whencreated
$info.LastLogonfromallDC = $lastlogon
$info.Expiredate =  (Get-ADUser $user -Properties msDS-UserPasswordExpiryTimeComputed| Select-Object -Property @{Name=“ExpiryDate”;Expression={[datetime]::FromFileTime($_.“msDS-UserPasswordExpiryTimeComputed”)}}).ExpiryDate


    
 $result += $info

}

$result