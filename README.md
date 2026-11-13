# Windows Firewall Maintenance CLI

An interactive PowerShell & Batch utility designed for Windows Server and workstation administrators to audit, deduplicate, backup, and restore Windows Defender Firewall policies safely.

## Features
- **Automatic UAC Elevation:** Includes a self-elevating `.bat` wrapper that cleanly requests Administrator privileges via a temporary VBS trigger without leaving residual files.
- **Smart Rule Deduplication:** Groups active Inbound and Outbound rules by `DisplayName`, `Direction`, and `Profile`, preserving the primary rule while purging redundant duplicates created by software updates or GPO drifts.
- **Prefix-Based Bulk Cleanup:** Safely removes orphaned or test firewall rules matching a specific naming prefix.
- **Binary Policy Backup & Restore:** Uses native `netsh advfirewall` commands to export and restore full `.wfw` policy snapshots before performing destructive changes.

## Usage
1. Clone or download this repository.
2. Double-click `launch_firewall_manager.bat` (it will automatically prompt for Administrator rights).
3. Select the desired maintenance task from the interactive CLI menu (`1-5`).

## Requirements
- Windows 10 / 11 or Windows Server 2016 / 2019 / 2022
- PowerShell 5.1 or higher
