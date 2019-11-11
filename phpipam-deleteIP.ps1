# Invoke API to phpipam to delete a IP address
#Autor 
#Sudo77
#12.11.2019

# Variables 

#VM Inventory names to match
$matchVMs = "vmtest01"


    #phpipam Info
    $phpipamURL = "https://myphpserver001"         #Phpipam Base URL
    $phpipamAppID = "vmware"                     #AppID in 
    $phpuser = "apiuser"
    $PHPcred = "apiuser123"
    $IPadress = get-vm -name $matchVMs | select @{N="IP Address";E={$_.guest.IPaddress[0]}}
    $ipdelete = $IPadress.'IP Address'

      
    $portgroup = "LAN - your network in phpipam"   #Discripton of your
   


########################################################################################################################
# phpipam API string 

    $baseAuthURL = $phpipamURL +"/api/$phpipamAppID/user/"
    # Authenticating with phpipam APIs
    $PHPcred = $PHPcred
    $authInfo = ("{0}:{1}" -f $PHPuser,$PHPcred)
    $authInfo = [System.Text.Encoding]::UTF8.GetBytes($authInfo)
    $authInfo = [System.Convert]::ToBase64String($authInfo)
    $headers = @{Authorization=("Basic {0}" -f $authInfo)}
    $sessionBody = '{"AuthenticationMethod": "1"}'
    $contentType = "application/json"
    Try{$iPamSessionResponse = Invoke-WebRequest -Uri $baseAuthURL -Headers $headers -Method POST -ContentType $contentType
          }Catch{Write-Host "Failed to authenticate to Ipam" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
     
#Extracting Token from the response, and adding it to the actual API
    $phpipamToken = ($iPamSessionResponse | ConvertFrom-Json).data.token
    $phpipamsessionHeader = @{"token"=$phpipamToken}

#Get All Sections for phpIpam to pull all subnets ***Not needed but here just incase an alternate use case would need it***
   # $SectionsURL =  $phpipamURL +"/api/$phpipamAppID/sections/"
   # $SectionJson = Invoke-WebRequest -Uri $SectionsURL -Headers $phpipamsessionHeader -Method GET -ContentType $contentType
   # $SectionData = ($SectionJson | ConvertFrom-Json).data | Select-Object name,id
    
#foreach Section Pull all Subnets.***Not needed but here just incase an alternate use case would need it***
    #$allSubnets = @()
    #Foreach($Section in $SectionData){
     #   $SectionID = $Section.id
     #   $GetSubnetsURL =  $phpipamURL +"/api/$phpipamAppID/sections/$Sectionid/subnets/"
     #   $GetSubnetsJson = Invoke-WebRequest -Uri $GetSubnetsURL -Headers $phpipamsessionHeader -Method GET -ContentType $contentType
     #   $GetSubnetData = ($GetSubnetsJson | ConvertFrom-Json).data | Select-Object id,description,subnet
     #   $allSubnets += $GetSubnetData
     #   }

#Set Subnet ID to Patch PortGroup ***Not needed but here just incase an alternate use case would need it***
 $subnetid = ($allSubnets | Where-Object {$_.description -eq $Portgroup}).id

#Get Data from Specific Subnet(Gateway, netmask, dns)
    Try{$IPURL = $phpipamURL +"/api/$phpipamAppID/addresses/search/$IPdelete/"
        $IPJson = Invoke-WebRequest -Uri $IPURL -Headers $phpipamsessionHeader -Method GET -ContentType $contentType
        $IPData = $IPJson | ConvertFrom-Json
        $IPSubnetID = $IPData.data.subnetid
         }Catch{Write-Host "Failed to get existing IP data from Ipam" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
    
#Setup request body to remove DNS Entry ***Not required - Depends on implementation of PhpIpam***
 #$JSONbody = 
  #  "{
   # ""remove_dns"":""1""
    #}"

#perform Remove 
    Try{$DeleteURL = $phpipamURL +"/api/$phpipamAppID/addresses/$IPdelete/"+"$IPSubnetID/"
        $Delete = Invoke-WebRequest -Uri $DeleteURL -Headers $phpipamsessionHeader -Method Delete -ContentType $contentType
        $Status = ($Delete | ConvertFrom-Json).message
         }Catch{Write-Host "Failed to Delete Address $IPAddress from IPAM" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
        if($Status -eq 'Address deleted'){
           Write-host $status
          # Exit;0
           }
        else{Write-host "$Status error"
            #Exit;1
        }




