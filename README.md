# AdvancedPowerShellToolkit

This repository contains a refactored, robust, and powerful collection of PowerShell scripts originally gathered by `nickrod518`. The scripts have been structured into a standard PowerShell Module format.

## Features

- **Massive Enterprise Scale**: Contains over 14,000 advanced PowerShell functions covering Active Directory, Azure, Exchange, Networking, CyberSecurity, and more.
- **Categorized Modules**: Logically grouped by domain to make finding tools easier.
- **Compiled Module Design**: A `Build-Module.ps1` script aggregates all tools into a single fast-loading `AdvancedPowerShellToolkit.psm1`.
- **Standardized Cmdlets**: Converted loose scripts into advanced functions using `[CmdletBinding()]`.
- **Pipeline Support**: Many functions natively accept pipeline input for batch processing.
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

## Available Domains

The toolkit covers 20 major IT administration domains, including:
- Active Directory & Identity Access Management
- Azure, VMware, & AWS
- Exchange & M365, SharePoint & Teams
- Windows Server & Hyper-V
- Linux & Unix
- Cloud Native, DevOps, & Kubernetes
- CyberSecurity & Networking
- Databases, End User Computing, SCCM & Intune
...and many more. 

See the `Docs/` folder for detailed capability tracking.

## Extending the Module & Compilation

To add new scripts:
1. Write an advanced function and save it as a `.ps1` file.
2. Drop it into the corresponding category folder inside the `Public/` directory.
3. Run `.\Build-Module.ps1` from the root of the repository to compile the `.psm1` file and update the module manifest (`.psd1`).
4. Reload the module using `Import-Module .\AdvancedPowerShellToolkit.psd1 -Force`.

## Documentation

Refer to the Markdown files in the `Docs/` directory for an exhaustive, categorized list of available commands and implementation status.

## License
MIT License
