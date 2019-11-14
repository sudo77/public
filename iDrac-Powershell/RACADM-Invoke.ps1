#RACADM variables
$racadmexe = "C:\Program Files\Dell\SysMgt\rac5\racadm.exe"
$racuser = "root"
$racpass = "pas`$word"
$ilo = "rzserver.test.com"


# enable smtp service
& $racadmexe  -r $ilo -u $racuser -p $racpass set iDRAC.IPMILan.AlertEnable 1


# set smtp address
& $racadmexe -r $ilo -u $racuser -p $racpass set iDRAC.RemoteHosts.SMTPServerIPAddress smtp.baywa.de

# mailadess to send Address 1 oder 2 oder 3
& $racadmexe -r $ilo -u $racuser -p $racpass set iDRAC.EmailAlert.Address.1 test@test.de

#aktiviert die email zeile 1   / 1=an 0=aus
& $racadmexe -r $ilo -u $racuser -p $racpass config -g cfgEmailAlert -o cfgEmailAlertEnable -i 1 1


# many other things, but the syntax is correct
