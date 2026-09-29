BeforeAll {
    . (Join-Path $PSScriptRoot '..\Invoke-StaleResourceCleanup.ps1')
    $script:AsOfDate = [datetime]'2026-09-29'
}

Describe 'Get-ResourceGroupClassification' {
    It 'marks protected resource groups first' {
        $tags = @{ purpose = 'copilot-hackathon'; owner = 'team'; expiresOn = '2025-01-01'; doNotDelete = 'true' }
        $result = Get-ResourceGroupClassification -Tags $tags -AsOfDate $script:AsOfDate
        $result.Status | Should -Be 'Protected'
        $result.EligibleForDelete | Should -BeFalse
    }

    It 'marks expired resource groups' {
        $tags = @{ owner = 'team'; expiresOn = '2025-01-01'; lastReviewed = '2026-09-01' }
        $result = Get-ResourceGroupClassification -Tags $tags -AsOfDate $script:AsOfDate
        $result.Status | Should -Be 'Expired'
        $result.EligibleForDelete | Should -BeTrue
    }

    It 'marks stale resource groups before missing owners' {
        $tags = @{ lastReviewed = '2025-06-01' }
        $result = Get-ResourceGroupClassification -Tags $tags -StaleAfterDays 30 -AsOfDate $script:AsOfDate
        $result.Status | Should -Be 'Stale'
    }

    It 'marks missing owner resource groups' {
        $tags = @{ expiresOn = '2027-01-01'; lastReviewed = '2026-09-29' }
        $result = Get-ResourceGroupClassification -Tags $tags -AsOfDate $script:AsOfDate
        $result.Status | Should -Be 'MissingOwner'
    }

    It 'marks invalid dates after owner checks' {
        $tags = @{ owner = 'team'; expiresOn = 'not-a-date'; lastReviewed = '2026-09-29' }
        $result = Get-ResourceGroupClassification -Tags $tags -AsOfDate $script:AsOfDate
        $result.Status | Should -Be 'Invalid'
        $result.EligibleForDelete | Should -BeFalse
    }

    It 'marks healthy resource groups ok' {
        $tags = @{ owner = 'team'; expiresOn = '2027-01-01'; lastReviewed = '2026-09-29' }
        $result = Get-ResourceGroupClassification -Tags $tags -AsOfDate $script:AsOfDate
        $result.Status | Should -Be 'Ok'
    }
}
