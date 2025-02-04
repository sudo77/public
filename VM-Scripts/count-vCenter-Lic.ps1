$currentDate = get-date -Format dd.MM.yyyy

$result = foreach ($licenseManager in (Get-View LicenseManager)) #-Server $vCenter.Name
{
    $vCenterName = ([System.uri]$licenseManager.Client.ServiceUrl).Host
    #($licenseManager.Client.ServiceUrl -split '/')[2]
    foreach ($license in $licenseManager.Licenses)
    {
        $licenseProp = $license.Properties
        $licenseExpiryInfo = $licenseProp | Where-Object {$_.Key -eq 'expirationDate'} | Select-Object -ExpandProperty Value
        if ($license.Name -eq 'Product Evaluation')
        {
            $expirationDate = 'Evaluation'
        } #if ($license.Name -eq 'Product Evaluation')
        elseif ($null -eq $licenseExpiryInfo)
        {
            $expirationDate = 'Never'
        } #elseif ($null -eq $licenseExpiryInfo)
        else
        {
            $expirationDate = $licenseExpiryInfo
        } #else #if ($license.Name -eq 'Product Evaluation')
    
        if ($license.Total -eq 0)
        {
            $totalLicenses = 'Unlimited'
        } #if ($license.Total -eq 0)
        else 
        {
            $totalLicenses = $license.Total
        } #else #if ($license.Total -eq 0)
    
        $licenseObj = New-Object psobject
        $licenseObj | Add-Member -Name Name -MemberType NoteProperty -Value $license.Name
        $licenseObj | Add-Member -Name LicenseKey -MemberType NoteProperty -Value $license.LicenseKey
        $licenseObj | Add-Member -Name ExpirationDate -MemberType NoteProperty -Value $expirationDate
        $licenseObj | Add-Member -Name ProductName -MemberType NoteProperty -Value ($licenseProp | Where-Object {$_.Key -eq 'ProductName'} | Select-Object -ExpandProperty Value)
        $licenseObj | Add-Member -Name ProductVersion -MemberType NoteProperty -Value ($licenseProp | Where-Object {$_.Key -eq 'ProductVersion'} | Select-Object -ExpandProperty Value)
        $licenseObj | Add-Member -Name EditionKey -MemberType NoteProperty -Value $license.EditionKey
        $licenseObj | Add-Member -Name Total -MemberType NoteProperty -Value $totalLicenses
        $licenseObj | Add-Member -Name Used -MemberType NoteProperty -Value $license.Used
        $licenseObj | Add-Member -Name CostUnit -MemberType NoteProperty -Value $license.CostUnit
        $licenseObj | Add-Member -Name Labels -MemberType NoteProperty -Value $license.Labels
        $licenseObj | Add-Member -Name vCenter -MemberType NoteProperty -Value $vCenterName
        $licenseObj
    } #foreach ($license in $licenseManager.Licenses)
} #foreach ($licenseManager in (Get-View LicenseManager)) #-Server $vCenter.Name


$result | Export-Excel -Path C:\00-Scripts\mup001-lic-$currentDate.xlsx