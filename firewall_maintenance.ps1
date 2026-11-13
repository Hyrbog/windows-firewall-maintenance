# ====================================================================
# GENERAL CONFIGURATION
# ====================================================================
$DefaultBackupPath = "$env:USERPROFILE\Desktop\Backup_Firewall.wfw"
$AuthorSignature   = "Windows Firewall Maintenance CLI | Benjamín Rubio"

# ====================================================================
# ADMINISTRATOR PRIVILEGE CHECK
# ====================================================================
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Error "This interactive console requires Administrator privileges."
    Exit
}

# ====================================================================
# MENU FUNCTIONS
# ====================================================================

# Option 1: Deduplicate identical Inbound/Outbound firewall rules
function Remove-DuplicateRules {
    Write-Host "`n[1] Scanning Windows Firewall for duplicate rules (Inbound/Outbound)..." -ForegroundColor Yellow
    Write-Host " Analyzing active system rules (this may take a moment)..." -ForegroundColor DarkGray
    
    $AllRules = Get-NetFirewallRule
    $RuleGroups = $AllRules | Group-Object DisplayName, Direction, Profile
    $DeletedCount = 0

    foreach ($Group in $RuleGroups) {
        if ($Group.Count -gt 1) {
            $DuplicateRules = $Group.Group | Select-Object -Skip 1
            foreach ($DupRule in $DuplicateRules) {
                try {
                    Remove-NetFirewallRule -Name $DupRule.Name -ErrorAction Stop
                    $DeletedCount++
                    Write-Host "    [X] Removed duplicate: $($DupRule.DisplayName) [$($DupRule.Direction)]" -ForegroundColor DarkGray
                } catch { continue }
            }
        }
    }
    Write-Host "`n[OK] Cleanup completed! Removed $DeletedCount redundant firewall rules." -ForegroundColor Green
}

# Option 2: Bulk remove rules matching a specific prefix
function Remove-RulesByPrefix {
    $Prefix = Read-Host "`nEnter the exact prefix of the rules to remove (e.g., APP_TEST_)"
    if ([string]::IsNullOrWhiteSpace($Prefix)) {
        Write-Warning "Prefix cannot be empty."
        return
    }

    Write-Host "`n[2] Searching Inbound and Outbound rules matching '$Prefix*'..." -ForegroundColor Yellow
    $MatchingRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "$Prefix*" }

    if ($MatchingRules) {
        $TotalToRemove = $MatchingRules.Count
        Write-Host " -> Found $TotalToRemove matching rules. Removing..." -ForegroundColor DarkYellow
        $MatchingRules | Remove-NetFirewallRule
        Write-Host "[OK] Operation finished! Successfully removed $TotalToRemove rules." -ForegroundColor Green
    } else {
        Write-Host " -> No rules found matching prefix '$Prefix'." -ForegroundColor Gray
    }
}

# Option 3: Export current firewall policy to a binary .wfw backup file
function Backup-FirewallPolicy {
    Write-Host "`n[3] Creating backup of current Windows Firewall configuration..." -ForegroundColor Yellow
    Write-Host " Target path: $DefaultBackupPath" -ForegroundColor DarkGray
    
    try {
        netsh advfirewall export $DefaultBackupPath | Out-Null
        Write-Host "[OK] Backup successfully saved to: $DefaultBackupPath" -ForegroundColor Green
    } catch {
        Write-Error "Unexpected error while exporting Windows Firewall policy."
    }
}

# Option 4: Restore firewall policy from the latest .wfw backup
function Restore-FirewallPolicy {
    Write-Host "`n[4] Preparing Windows Firewall policy restoration..." -ForegroundColor Yellow
    
    if (-not (Test-Path -Path $DefaultBackupPath)) {
        Write-Warning "No backup file found at: $DefaultBackupPath"
        Write-Host "Please run Option 3 first to generate a valid backup." -ForegroundColor Gray
        return
    }

    $Confirm = Read-Host "WARNING: Restoring will overwrite all current firewall rules. Continue? (Y/N)"
    if ($Confirm -eq 'Y' -or $Confirm -eq 'y') {
        try {
            netsh advfirewall import $DefaultBackupPath | Out-Null
            Write-Host "[OK] Windows Firewall successfully restored from backup!" -ForegroundColor Green
        } catch {
            Write-Error "Critical error importing the firewall policy file."
        }
    } else {
        Write-Host "-> Operation cancelled by user." -ForegroundColor Gray
    }
}

# ====================================================================
# MAIN INTERACTIVE MENU LOOP
# ====================================================================
do {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "       WINDOWS FIREWALL MAINTENANCE CLI           " -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " 1. Remove duplicate rules (Inbound & Outbound)"
    Write-Host " 2. Bulk remove rules by custom prefix"
    Write-Host " 3. Backup firewall policy (.wfw to Desktop)"
    Write-Host " 4. Restore firewall policy from latest backup"
    Write-Host " 5. Exit"
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host " $AuthorSignature" -ForegroundColor DarkGray
    Write-Host "==================================================" -ForegroundColor Cyan
    
    $Choice = Read-Host "`nSelect an option (1-5)"

    switch ($Choice) {
        "1" { Remove-DuplicateRules }
        "2" { Remove-RulesByPrefix }
        "3" { Backup-FirewallPolicy }
        "4" { Restore-FirewallPolicy }
        "5" { Write-Host "`nClosing console. Goodbye!`n" -ForegroundColor Green; break }
        Default { Write-Warning "Invalid option. Please enter a number between 1 and 5." }
    }

    if ($Choice -ne "5") {
        Write-Host "`nPress any key to return to the main menu..."
        $null = [System.Console]::ReadKey($true)
    }

} while ($Choice -ne "5")
