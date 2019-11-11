# Powershell Script Invoke API request to phpipam to get the next free ip in certain network
#Autor 
#Sudo77
#12.11.2019

------------------------------------------------
# Configure the variables 
------------------------------------------------
    #phpipam Info
    $phpipamURL = "https://myphpserver001"         #Phpipam Base URL       
    $phpipamAppID = "vmware"                       #AppID 
    $Description = "Created by deployscript"       #Tag for each Entry Created in phpipam 
    $phpuser = "apiuser"
    $PHPcred = "apiuser123"
    
    $portgroup = "LAN - your network in phpipam"   #Discripton of your net in phpipam
    
    
    $matchVMs = "vmtest99"
    $Description = "created by script"
    $Requester = " Autodeploy"
-----------------------------------------------------
# phpipam API string

    $baseAuthURL = $phpipamURL +"/api/$phpipamAppID/user/"
    # Authenticating with phpipam APIs
  
    $authInfo = ("{0}:{1}" -f $phpuser,$PHPcred)
    $authInfo = [System.Text.Encoding]::UTF8.GetBytes($authInfo)
    $authInfo = [System.Convert]::ToBase64String($authInfo)
    $headers = @{Authorization=("Basic {0}" -f $authInfo)}
    $sessionBody = '{"AuthenticationMethod": "1"}'
    $contentType = "application/json"
    Try{$iPamSessionResponse = Invoke-WebRequest -Uri $baseAuthURL -Headers $headers -Method POST -ContentType $contentType
        }Catch{Write-Host "Failed to Authenticate to Ipam" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
--------------------------------------------------------
#Extracting Token from the response, and adding it to the actual API
    $phpipamToken = ($iPamSessionResponse | ConvertFrom-Json).data.token
    $phpipamsessionHeader = @{"token"=$phpipamToken}


    write-host "Token = " $phpipamToken -ForegroundColor Yellow
---------------------------------------------------------
#Get All Sections for phpIpam to pull all subnets
    $SectionsURL =  $phpipamURL +"/api/$phpipamAppID/sections/"
    Try{$SectionJson = Invoke-WebRequest -Uri $SectionsURL -Headers $phpipamsessionHeader -Method GET -ContentType $contentType
        $SectionData = ($SectionJson | ConvertFrom-Json).data | Select-Object name,id
         }Catch {Write-Host "Failed to Authenticate to get Sections from Ipam" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
    
#foreach Section Pull all Subnets.
    Try{
    $allSubnets = @()
    Foreach($Section in $SectionData){
        $SectionID = $Section.id
        $GetSubnetsURL =  $phpipamURL +"/api/$phpipamAppID/sections/$Sectionid/subnets/"
        $GetSubnetsJson = Invoke-WebRequest -Uri $GetSubnetsURL -Headers $phpipamsessionHeader -Method GET -ContentType $contentType
        $GetSubnetData = ($GetSubnetsJson | ConvertFrom-Json).data | Select-Object id,description,subnet
        $allSubnets += $GetSubnetData
        }
        }Catch {Write-Host "Failed to Get Subnets from Ipam" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }
#Set Subnet ID to Patch PortGroup
    $subnetid = ($allSubnets | Where-Object {$_.description -eq $Portgroup}).id
    Write-host "Working on " $subnetid $portgroup -ForegroundColor Yellow

#Get Data from Specific Subnet(Gateway, netmask, dns)
    Try{$SubnetURL = $phpipamURL +"/api/$phpipamAppID/subnets/$subnetid/"
        $SubNetJson = Invoke-WebRequest -Uri $SubnetURL -Headers $phpipamsessionHeader -Method GET -ContentType $contentType
        $SubnetData = $SubNetJson | ConvertFrom-Json
        $Gateway = $SubnetData.data.gateway.ip_addr
        $Netmask = $SubnetData.data.calculation.'Subnet netmask'
        #$PrimaryDNS = ($SubnetData.data.nameservers.namesrv1).Split(';')[0]
        #$SecondaryDNS = ($SubnetData.data.nameservers.namesrv1).Split(';')[1]
        }Catch {Write-Host "Failed to retrieve subnet data from Ipam" -ForegroundColor Red
                $error[0] | Format-List -Force
                Exit 1
                }

########################   get next free ip ################################################

#Setup request body 

    $JSONbody = 
    "{
    ""description"":""$Description"",
    ""owner"":""$Requester"",
    ""hostname"":""$matchVMs""
    }"

#Perform Get Request for next available IP from phpipam

                $nextFreeURL = $phpipamURL +"/api/$phpipamAppID/addresses/first_free/$subnetid/"
                $nextfreeRequest = Invoke-WebRequest -Uri $nextFreeURL -Headers $phpipamsessionHeader -Body $JSONbody -Method POST -ContentType $contentType
                $nextFreeIP = ($nextfreeRequest | ConvertFrom-Json).data 
                $Status = ($nextfreeRequest | ConvertFrom-Json).message
                if($Status -eq 'Address created'){
                     Write-host $status}
                elseif($Status -ne 'Address created')
                      {Write-host "Failed to Get net IP fro IPAM" -ForegroundColor Red
                       Exit;1}
                 Write-host "found IP " $nextFreeIP "Gateway " $Gateway " Netmask" $Netmask  -ForegroundColor Yellow

#Setup Json param body to post to the service

##### Ping Test##### exit if IP ping response


