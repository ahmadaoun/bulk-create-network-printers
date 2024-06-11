# Function to create Install.ps1 script
function Create-InstallScript {
    param (
        [string]$installPath,
        [string]$server,
        [string]$printer
    )

    $installScript = @"
Param(
    [Parameter(Mandatory = `$true)]
    [ValidateSet("Install", "Uninstall")]
    [String[]]
    `$Mode
)
`$server = "$server"
`$PrinterName = "$printer"
If (`$Mode -eq "Install") {
    if ((Test-NetConnection -ComputerName `$server | Select-Object -ExpandProperty PingSucceeded)) {
        Add-Printer -ConnectionName "\\`$server\`$PrinterName"
    }
}
If (`$Mode -eq "Uninstall") {
    Remove-Printer -Name "\\`$server\`$PrinterName"
}
"@

    $installScript | Out-File -FilePath $installPath -Encoding utf8
}

# Function to create Detect.ps1 script
function Create-DetectScript {
    param (
        [string]$detectPath,
        [string]$server,
        [string]$printer
    )

    $detectScript = @"
# Detection
`$server = "$server"
`$PrinterName = "$printer"
if (Test-Path "HKCU:\Printers\Connections\,,`$server,`$PrinterName") {
    "Installed"
} else {
}
"@

    $detectScript | Out-File -FilePath $detectPath -Encoding utf8
}

# Function to create .intunewin file using IntuneWinAppUtil.exe
function Create-IntuneWinFile {
    param (
        [string]$sourceFolder,
        [string]$setupFile,
        [string]$outputFolder
    )

    $intuneWinAppUtilPath = "$PSScriptRoot\IntuneWinAppUtil.exe" # Path to IntuneWinAppUtil.exe
    $arguments = @(
        "-c", $sourceFolder,
        "-s", $setupFile,
        "-o", $outputFolder
    )
    
    & $intuneWinAppUtilPath @arguments
}

# Get the list of printers from a CSV file
$data = Import-Csv -Path "$PSScriptRoot\Printers.csv"

# Ensure $data is treated as an array even if it has a single entry
if ($data -isnot [System.Collections.IEnumerable]) {
    $data = @($data)
}

foreach ($entry in $data) {
    $printer = $entry.Printers
    $server = $entry.Servers

    $folderPath = "$PSScriptRoot\$printer"
    $installPath = "$folderPath\Install.ps1"
    $detectPath = "$PSScriptRoot\$printer\Detect.ps1"

    # Create folder structure
    New-Item -ItemType Directory -Path $folderPath -Force | Out-Null

    # Create scripts
    Create-InstallScript -installPath $installPath -server $server -printer $printer
    Create-DetectScript -detectPath $detectPath -server $server -printer $printer

    # Create .intunewin file
    $outputFolder = "$PSScriptRoot\IntuneWinFiles"
    Create-IntuneWinFile -sourceFolder $folderPath -setupFile $installPath -outputFolder $folderPath
}