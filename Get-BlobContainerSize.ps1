if (!(Get-Module -ListAvailable Az.*)) {
    Write-Host "Please install the new Azure Powershell Module at `nhttps://docs.microsoft.com/en-us/powershell/azure/install-az-ps"
    exit 1
}

try {
    $subs = Get-AzSubscription
} catch {
    Connect-AzAccount
    $subs = Get-AzSubscription
}

do {
    $checkError = $False
    $activeSub = Read-Host -Prompt "Please enter the name of the Subscription that contains the Storage Accounts"

    try {
        set-azcontext -Subscription ($subs.where({$_.name -eq $activeSub}).id)
    } catch {
        Write-Host "Sub $activeSub not found. Please choose from subs below:"
        $subs.ForEach({Write-Host $_.name})
        $checkError = $True
    }
}while($checkError)

do {
    $checkError = $False
    $targetSA = Read-Host -Prompt "Please enter the name of the Storage Account"
    $rg = Read-Host -Prompt "Please enter the name of the Resource Group"

    try {
        $sa = get-azstorageaccount -ResourceGroupName $rg -Name $targetSA
    } catch {
        Write-Host "SA $targetSA not found. Please choose from SA below:"
        Get-AZStroageAccount
        $checkError = $True
    }
}while($checkError)

Get-AzStorageContainer -Context $sa.Context | % {
    $Token = $Null
    $length = 0
    $count = 0
    do {
        $Blobs = Get-AzStorageBlob -Container $_.Name -MaxCount 100  -ContinuationToken $Token -Context $sa.Context
        $count+=$Blobs.Count
        Write-Host "Found $count blobs in Container $($_.Name)..."
        if($Blobs.Length -le 0) { Break;}
        $Token = $Blobs[$Blobs.Count -1].ContinuationToken;
        $Blobs | ForEach-Object {$length = $length + $_.pLength}    
    } while ($Token -ne $Null)

    Write-Host " "
    Write-Host "Total Length of $($_.Name) is $length"
}
