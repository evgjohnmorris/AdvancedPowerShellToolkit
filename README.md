# AdvancedPowerShellToolkit

This repository contains a refactored, robust, and powerful collection of PowerShell scripts originally gathered by `nickrod518`. The scripts have been structured into a standard PowerShell Module format.

## Features

- **Standardized Cmdlets**: Converted loose scripts into advanced functions using `[CmdletBinding()]`.
- **Pipeline Support**: Many functions now natively accept pipeline input for batch processing.
- **Robust Error Handling**: Added `try/catch` blocks and proper error logging.
- **CIM over WMI**: Updated older WMI calls to use modern CIM instances (`Get-CimInstance`).
- **CI/CD Integration**: Includes a GitHub Action to automatically run `PSScriptAnalyzer` on every push to ensure code quality.

## Installation

You can import this module directly on your machine:

```powershell
# Clone the repository
git clone https://github.com/<YOUR_GITHUB_USERNAME>/AdvancedPowerShellToolkit.git

# Navigate to the directory
cd AdvancedPowerShellToolkit

# Import the module
Import-Module .\AdvancedPowerShellToolkit.psd1
```

## Available Commands

Currently, the following enhanced commands are available in the `Public` directory:

- `Get-ComputerNetInfo` - Retrieves basic network information (DNS, IP, MAC).
- `Get-WindowsDiskInfo` - Retrieves partition and logical volume information.
- `Get-WindowsServerLoad` - Retrieves current CPU and Memory load percentages.
- `Get-WindowsTimeOffset` - Retrieves the NTP time offset for a computer.
- `Get-ADUserTrueLastLogon` - Retrieves the true LastLogon time across all Domain Controllers.
- `Restart-WindowsServer` - Safely restarts Windows servers with connection checks and ShouldProcess support.

## Extending the Module

To add new scripts:
1. Write an advanced function and save it as a `.ps1` file.
2. Drop it into the `Public` folder.
3. Reload the module using `Import-Module .\AdvancedPowerShellToolkit.psd1 -Force`.

## License
MIT License
