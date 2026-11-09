# =====================================
# ISOHub - Update Catalog
# =====================================

$CatalogPath = ".\data\os.json"

function Get-Ubuntu {
    try {

        $Version = "Unknown"

        $page = Invoke-WebRequest `
            -Uri "https://releases.ubuntu.com/" `
            -UseBasicParsing

        if ($page.Content -match 'ubuntu-([\d\.]+)-desktop-amd64\.iso')
        {
            $Version = $Matches[1]
        }
        Write-Host "Ubuntu : $Version"
        return @{
            Name         = "Ubuntu"
            Version      = "$Version LTS"
            Type         = "Linux"
            Architecture = "amd64"
            FileName     = "ubuntu-$Version-desktop-amd64.iso"
            Vendor       = "Canonical"
            Size         = "~6 GB"
            Url          = "https://releases.ubuntu.com/$Version/ubuntu-$Version-desktop-amd64.iso"
            SHA256       = ""
        }

    }
    catch {
        Write-Warning "Ubuntu update failed"
    }
}

function Get-Kali {

    try {

        $page = Invoke-WebRequest `
            -Uri "https://cdimage.kali.org/current/" `
            -UseBasicParsing

        if ($page.Content -match 'kali-linux-([\d\.]+)-installer-amd64\.iso')
        {
            $Version = $Matches[1]
            Write-Host "Kali : $Version"
            return @{
                Name         = "Kali"
                Version      = $Version
                Type         = "Linux"
                Architecture = "x64"
                FileName     = "kali-linux-$Version-installer-amd64.iso"
                Vendor       = "Offensive Security"
                Size         = "~4.5 GB"
                Url          = "https://cdimage.kali.org/current/kali-linux-$Version-installer-amd64.iso"
                SHA256       = ""
            }
        }
    }
    catch {
        Write-Warning "Kali update failed"
    }
}

function Get-Debian {

    try {

        $page = Invoke-WebRequest `
            -Uri "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/" `
            -UseBasicParsing

        if ($page.Content -match 'debian-([\d\.]+)-amd64-netinst\.iso')
        {
            $Version = $Matches[1]
            Write-Host "Debian : $Version"
            return @{
                Name         = "Debian"
                Version      = $Version
                Type         = "Linux"
                Architecture = "amd64"
                FileName     = "debian-$Version-amd64-netinst.iso"
                Vendor       = "Debian Project"
                Size         = "~650 MB"
                Url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-$Version-amd64-netinst.iso"
                SHA256       = ""
            }
        }
    }
    catch {
        Write-Warning "Debian update failed"
    }
}

function Get-Windows11 {

    try {

        $Version = "Latest"

        $page = Invoke-WebRequest `
            -Uri "https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information" `
            -UseBasicParsing

        if ($page.Content -match 'Version ([0-9]{2}H[0-9])')
        {
            $Version = $Matches[1]
        }
        Write-Host "Windows 11 : $Version"
        return @{
            Name         = "Windows 11"
            Version      = $Version
            Type         = "Windows"
            Architecture = "x64"
            FileName     = "MediaCreationTool_W11.exe"
            Vendor       = "Microsoft"
            Size         = "20 MB"
            Url          = "https://go.microsoft.com/fwlink/?linkid=2156295"
            SHA256       = ""
        }
    }
    catch {
        Write-Warning "Windows 11 update failed"
    }
}

function Get-Windows10 {
    Write-Host "Windows 10 : $Version"
    return @{
        Name         = "Windows 10"
        Version      = "22H2"
        Type         = "Windows"
        Architecture = "x64"
        FileName     = "MediaCreationTool_W10.exe"
        Vendor       = "Microsoft"
        Size         = "20 MB"
        Url          = "https://go.microsoft.com/fwlink/?LinkId=2265055"
        SHA256       = ""
    }
}

function Get-Rufus {
    Write-Host "Refus : $Version"
    return @{
        Name         = "Rufus"
        Version      = "Latest"
        Type         = "Tool"
        Architecture = "x64"
        FileName     = "rufus.exe"
        Vendor       = "Rufus"
        Size         = ""
        Url          = "https://github.com/pbatard/rufus/releases/latest/download/rufus.exe"
        SHA256       = ""
    }
}

function Get-Ventoy {

    return @{
        Name         = "Ventoy"
        Version      = "Latest"
        Type         = "Tool"
        Architecture = "x64"
        FileName     = "ventoy.zip"
        Vendor       = "Ventoy"
        Size         = ""
        Url          = "https://github.com/ventoy/Ventoy/releases/latest"
        SHA256       = ""
    }
}

function Get-BalenaEtcher {

    return @{
        Name         = "Etcher Balena"
        Version      = "Latest"
        Type         = "Tool"
        Architecture = "x64"
        FileName     = "balenaEtcher.exe"
        Vendor       = "Balena"
        Size         = ""
        Url          = "https://github.com/balena-io/etcher/releases/latest"
        SHA256       = ""
    }
}

$Catalog = @()

$Catalog += Get-Ubuntu
$Catalog += Get-Kali
$Catalog += Get-Debian
$Catalog += Get-Windows11
$Catalog += Get-Windows10
$Catalog += Get-Rufus
$Catalog += Get-Ventoy
$Catalog += Get-BalenaEtcher

$Catalog |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        -Path $CatalogPath `
        -Encoding UTF8

Write-Host ""
Write-Host "Catalog updated successfully."
Write-Host "Entries:" $Catalog.Count