<#
.SYNOPSIS
    Reports and optionally removes stale Azure resource groups.
.DESCRIPTION
    Classifies resource groups in a subscription and writes a CSV report. The priority order is:
    1. Protected: protected tag value is true.
    2. Expired: expiresOn tag is a yyyy-MM-dd date earlier than AsOfDate.
    3. Stale: lastReviewed tag is a yyyy-MM-dd date older than StaleAfterDays.
    4. MissingOwner: owner tag is missing or blank.
    5. Invalid: expiresOn or lastReviewed exists but is not yyyy-MM-dd.
    6. Ok: no cleanup condition matched.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SubscriptionId,
    [string]$NamePrefix = 'rg-',
    [hashtable]$TagFilter = @{ purpose = 'copilot-hackathon' },
    [ValidateRange(1, 3650)]
    [int]$StaleAfterDays = 30,
    [string]$ReportPath = (Join-Path -Path (Get-Location) -ChildPath 'stale-resource-groups.csv'),
    [switch]$Delete,
    [string]$ProtectedTagName = 'doNotDelete',
    [datetime]$AsOfDate = (Get-Date)
)

function ConvertTo-TagDate {
    [CmdletBinding()]
    param([AllowNull()][object]$Value)
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return $null }
    $parsedDate = [datetime]::MinValue
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $styles = [System.Globalization.DateTimeStyles]::AssumeLocal
    if ([datetime]::TryParseExact([string]$Value, 'yyyy-MM-dd', $culture, $styles, [ref]$parsedDate)) {
        return $parsedDate.Date
    }
    throw "Date tag value '$Value' must use yyyy-MM-dd."
}

function Test-TruthyTag {
    [CmdletBinding()]
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return $false }
    return @('true', '1', 'yes') -contains ([string]$Value).Trim().ToLowerInvariant()
}

function Test-TagFilter {
    [CmdletBinding()]
    param([AllowNull()][hashtable]$Tags, [hashtable]$TagFilter, [string]$Name, [string]$NamePrefix)
    if (-not $Name.StartsWith($NamePrefix, [System.StringComparison]::OrdinalIgnoreCase)) { return $false }
    foreach ($key in $TagFilter.Keys) {
        if ($null -eq $Tags -or -not $Tags.ContainsKey($key)) { return $false }
        if ([string]$Tags[$key] -ne [string]$TagFilter[$key]) { return $false }
    }
    return $true
}

function Get-ResourceGroupClassification {
    [CmdletBinding()]
    param(
        [AllowNull()][hashtable]$Tags,
        [int]$StaleAfterDays = 30,
        [string]$ProtectedTagName = 'doNotDelete',
        [datetime]$AsOfDate = (Get-Date)
    )
    $safeTags = @{}
    if ($null -ne $Tags) { $safeTags = $Tags }
    if ($safeTags.ContainsKey($ProtectedTagName) -and (Test-TruthyTag -Value $safeTags[$ProtectedTagName])) {
        return [pscustomobject]@{ Status = 'Protected'; Reason = "$ProtectedTagName tag is true"; EligibleForDelete = $false }
    }

    $expiresOn = $null
    $lastReviewed = $null
    $invalidDates = [System.Collections.Generic.List[string]]::new()
    if ($safeTags.ContainsKey('expiresOn')) {
        try { $expiresOn = ConvertTo-TagDate -Value $safeTags['expiresOn'] } catch { $invalidDates.Add('expiresOn') }
    }
    if ($safeTags.ContainsKey('lastReviewed')) {
        try { $lastReviewed = ConvertTo-TagDate -Value $safeTags['lastReviewed'] } catch { $invalidDates.Add('lastReviewed') }
    }

    if ($null -ne $expiresOn -and $expiresOn.Date -lt $AsOfDate.Date) {
        return [pscustomobject]@{ Status = 'Expired'; Reason = "expiresOn $($expiresOn.ToString('yyyy-MM-dd')) is before $($AsOfDate.ToString('yyyy-MM-dd'))"; EligibleForDelete = $true }
    }
    if ($null -ne $lastReviewed) {
        $cutoff = $AsOfDate.Date.AddDays(-1 * $StaleAfterDays)
        if ($lastReviewed.Date -lt $cutoff) {
            return [pscustomobject]@{ Status = 'Stale'; Reason = "lastReviewed $($lastReviewed.ToString('yyyy-MM-dd')) is before $($cutoff.ToString('yyyy-MM-dd'))"; EligibleForDelete = $true }
        }
    }
    if (-not $safeTags.ContainsKey('owner') -or [string]::IsNullOrWhiteSpace([string]$safeTags['owner'])) {
        return [pscustomobject]@{ Status = 'MissingOwner'; Reason = 'owner tag is missing or blank'; EligibleForDelete = $true }
    }
    if ($invalidDates.Count -gt 0) {
        return [pscustomobject]@{ Status = 'Invalid'; Reason = "Invalid date tag(s): $($invalidDates -join ', ')"; EligibleForDelete = $false }
    }
    return [pscustomobject]@{ Status = 'Ok'; Reason = 'Resource group is within policy'; EligibleForDelete = $false }
}

function ConvertTo-CleanupReportRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$ResourceGroup,
        [Parameter(Mandatory)][object]$Classification,
        [Parameter(Mandatory)][string]$SubscriptionId,
        [Parameter(Mandatory)][int]$ResourceCount,
        [Parameter(Mandatory)][string]$Action
    )
    $tags = @{}
    if ($null -ne $ResourceGroup.Tags) { $tags = $ResourceGroup.Tags }
    [pscustomobject]@{
        SubscriptionId = $SubscriptionId
        ResourceGroup = $ResourceGroup.ResourceGroupName
        Location = $ResourceGroup.Location
        Owner = if ($tags.ContainsKey('owner')) { [string]$tags['owner'] } else { '' }
        ExpiresOn = if ($tags.ContainsKey('expiresOn')) { [string]$tags['expiresOn'] } else { '' }
        LastReviewed = if ($tags.ContainsKey('lastReviewed')) { [string]$tags['lastReviewed'] } else { '' }
        ResourceCount = $ResourceCount
        Status = $Classification.Status
        Reason = $Classification.Reason
        Action = $Action
    }
}

function Invoke-StaleResourceCleanup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$SubscriptionId,
        [string]$NamePrefix = 'rg-',
        [hashtable]$TagFilter = @{ purpose = 'copilot-hackathon' },
        [ValidateRange(1, 3650)][int]$StaleAfterDays = 30,
        [string]$ReportPath = (Join-Path -Path (Get-Location) -ChildPath 'stale-resource-groups.csv'),
        [switch]$Delete,
        [string]$ProtectedTagName = 'doNotDelete',
        [datetime]$AsOfDate = (Get-Date)
    )
    Write-Verbose "Selecting Azure subscription $SubscriptionId"
    Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop | Out-Null
    $resourceGroups = Get-AzResourceGroup -ErrorAction Stop
    $matchedGroups = $resourceGroups | Where-Object { Test-TagFilter -Tags $_.Tags -TagFilter $TagFilter -Name $_.ResourceGroupName -NamePrefix $NamePrefix }
    $rows = $matchedGroups | ForEach-Object {
        $resourceGroup = $_
        Write-Verbose "Evaluating resource group $($resourceGroup.ResourceGroupName)"
        $classification = Get-ResourceGroupClassification -Tags $resourceGroup.Tags -StaleAfterDays $StaleAfterDays -ProtectedTagName $ProtectedTagName -AsOfDate $AsOfDate
        $resources = @(Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName -ErrorAction Stop)
        $action = 'Skipped'
        if ($classification.EligibleForDelete -and $Delete) {
            $target = "resource group $($resourceGroup.ResourceGroupName)"
            if ($PSCmdlet.ShouldProcess($target, 'Remove-AzResourceGroup')) {
                try {
                    $removeParameters = @{ Name = $resourceGroup.ResourceGroupName; Force = $true; ErrorAction = 'Stop' }
                    Remove-AzResourceGroup @removeParameters | Out-Null
                    $action = 'Deleted'
                } catch {
                    $action = 'Skipped'
                    Write-Verbose "Deletion failed for $($resourceGroup.ResourceGroupName): $($_.Exception.Message)"
                }
            } else { $action = 'WouldDelete' }
        }
        ConvertTo-CleanupReportRow -ResourceGroup $resourceGroup -Classification $classification -SubscriptionId $SubscriptionId -ResourceCount $resources.Count -Action $action
    }
    $reportDirectory = Split-Path -Path $ReportPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($reportDirectory) -and -not (Test-Path -Path $reportDirectory)) {
        New-Item -Path $reportDirectory -ItemType Directory -Force -WhatIf:$false | Out-Null
    }
    $rows | Sort-Object ResourceGroup | Export-Csv -Path $ReportPath -NoTypeInformation -WhatIf:$false
    Write-Verbose "Report written to $ReportPath"
    return $rows
}

if ($MyInvocation.InvocationName -ne '.') {
    $invokeParameters = @{ SubscriptionId = $SubscriptionId; NamePrefix = $NamePrefix; TagFilter = $TagFilter; StaleAfterDays = $StaleAfterDays; ReportPath = $ReportPath; Delete = $Delete; ProtectedTagName = $ProtectedTagName; AsOfDate = $AsOfDate }
    Invoke-StaleResourceCleanup @invokeParameters
}
