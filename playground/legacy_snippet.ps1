# Small excerpt that inspired the naive Python port. It is intentionally incomplete.
if ($classification.EligibleForDelete -and $Delete) {
    $target = "resource group $($resourceGroup.ResourceGroupName)"
    if ($PSCmdlet.ShouldProcess($target, 'Remove-AzResourceGroup')) {
        Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force -ErrorAction Stop | Out-Null
        $action = 'Deleted'
    } else {
        $action = 'WouldDelete'
    }
}

$rows | Sort-Object ResourceGroup | Export-Csv -Path $ReportPath -NoTypeInformation -WhatIf:$false
