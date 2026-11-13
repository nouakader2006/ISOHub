# Load current catalog
# Backup catalog
# Get latest Linux versions
# Compare with existing entries
# Build catalog
# Save catalog
# =======================================
# Paths
# =======================================

$DataFolder  = ".\data"
$CatalogFile = Join-Path $DataFolder "os.json"
$BackupFile  = Join-Path $DataFolder "os_backup.json"

# =======================================
# Load catalog
# =======================================

$CurrentCatalog = Get-Content $CatalogFile -Raw | ConvertFrom-Json

Copy-Item $CatalogFile $BackupFile -Force

Write-Host "Catalog backup created"
function Get-CatalogEntry {
    param(
        [string]$Name
    )

    return $CurrentCatalog |
        Where-Object Name -eq $Name |
        Select-Object -First 1
}

#==================================
#Ubuntu
#==================================
function Get-UbuntuLatest {

    $Current = Get-CatalogEntry "Ubuntu"

    try {
        Write-Host "Checking Ubuntu..."

        $Page = Invoke-WebRequest `
            -Uri "https://ubuntu.com/download/desktop"

        $Match = [regex]::Match(
            $Page.Content,
            'Ubuntu\s+(\d+\.\d+(?:\.\d+)?)\s+LTS'
        )

        if (-not $Match.Success) {
            Write-Warning "Unable to detect Ubuntu version"
            return $Current
        }

        $Version = $Match.Groups[1].Value

        $FileName = "ubuntu-$Version-desktop-amd64.iso"

        $IsoUrl = "https://releases.ubuntu.com/$Version/$FileName"

        if ($Current.Version -like "$Version*") {

            Write-Host "[OK] Ubuntu already up to date ($Version)"

            return $Current
        }

        Write-Host "[UPDATE] Ubuntu $($Current.version) -> $Version LTS"

        return @{
            Name         = "Ubuntu"
            Version      = "$Version LTS"
            Architecture = "amd64"
            FileName     = $FileName
            Vendor       = "Canonical"
            Type         = "Linux"
            Category     = "Linux"
            Size         = "~6 GB"
            Url          = $IsoUrl
            SHA256       = ""
        }
    }
    catch {

        Write-Warning "Ubuntu update failed: $_"

        return $Current
    }
}

#==================================
#Kali
#==================================
function Get-KaliLatest {

    $Current = Get-CatalogEntry "Kali"

    try {

        $Page = Invoke-WebRequest `
            "https://cdimage.kali.org/current/"

        $Match = [regex]::Match(
            $Page.Content,
            'kali-linux-(\d+\.\d+)-installer-amd64\.iso'
        )

        if (-not $Match.Success) {
            return $Current
        }

        $Version = $Match.Groups[1].Value

          if ($Current.Version -like "$Version*") {

            Write-Host "[OK] Kali already up to date ($Version)"

            return $Current
        }

        Write-Host "[UPDATE] Kali $($Current.version) -> $Version Kali Linux"

        return @{
            Name         = "Kali"
            Version      = $Version
            Architecture = "x64"
            FileName     = "kali-linux-$Version-installer-amd64.iso"
            Vendor       = "Offensive Security"
            Type         = "Linux"
            Category     = "Linux"
            Size         = "~4.5 GB"
            Url          = "https://cdimage.kali.org/current/kali-linux-$Version-installer-amd64.iso"
            SHA256       = ""
        }
    }
    catch {
        return $Current
    }
}

#==================================
#Debian
#==================================
function Get-DebianLatest {

    $Current = Get-CatalogEntry "Debian"

    try {

        $Page = Invoke-WebRequest `
            "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/"

        $Match = [regex]::Match(
            $Page.Content,
            'debian-(\d+\.\d+\.\d+)-amd64-netinst\.iso'
        )

        if (-not $Match.Success) {
            return $Current
        }

        $Version = $Match.Groups[1].Value

           if ($Current.Version -like "$Version*") {

            Write-Host "[OK] Debian already up to date ($Version)"

            return $Current
        }

        Write-Host "[UPDATE] Debian $($Current.version) -> $Version LTS"

        return @{
            Name         = "Debian"
            Version      = $Version
            Architecture = "amd64"
            FileName     = "debian-$Version-amd64-netinst.iso"
            Vendor       = "Debian Project"
            Type         = "Linux"
            Category     = "Linux"
            Size         = "~650 MB"
            Url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-$Version-amd64-netinst.iso"
            SHA256       = ""
        }
    }
    catch {
        return $Current
    }
}

#==================================
#Windows 
#==================================
$Windows11 = Get-CatalogEntry "Windows 11"
$Windows10 = Get-CatalogEntry "Windows 10"
#==================================
#Utility 
#==================================
$Rufus  = Get-CatalogEntry "Rufus"
$Ventoy = Get-CatalogEntry "Ventoy"
$Etcher = Get-CatalogEntry "Etcher Balena"
#==================================
# Virtualization
#==================================
$ProxMox = Get-CatalogEntry "ProxMox"
#==================================
# CyberSécurity
#==================================
$Gobuster = Get-CatalogEntry "Gobuster"
$BurpSuite = Get-CatalogEntry "Burp Suite"
$Nmap = Get-CatalogEntry "Nmap"
#==================================
#Final Generate 
#==================================
$Catalog = @()

$Ubuntu = Get-UbuntuLatest
if ($Ubuntu) { $Catalog += $Ubuntu }

$Kali = Get-KaliLatest
if ($Kali) { $Catalog += $Kali }

$Debian = Get-DebianLatest
if ($Debian) { $Catalog += $Debian }

$Catalog += $Windows11
$Catalog += $Windows10

$Catalog += $Rufus
$Catalog += $Ventoy
$Catalog += $Etcher
$Catalog += $ProxMox
$Catalog += $Gobuster
$Catalog += $BurpSuite
$Catalog += $Nmap

#==================================
#Save
#==================================
$Catalog |
ConvertTo-Json -Depth 10 |
Set-Content $CatalogFile -Encoding UTF8
Write-Host ""
Write-Host "=============================="
Write-Host "UPDATE SUMMARY"
Write-Host "=============================="

$Catalog |
    Select-Object Name, Version |
    Format-Table -AutoSize
Write-Host ""
Write-Host "Catalog updated successfully"
Write-Host "Entries : $($Catalog.Count)"