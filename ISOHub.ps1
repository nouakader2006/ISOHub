# =======================================
# ISOHub
# =======================================
# Author      : Abdelkader Nouacer
# GitHub      : https://github.com/nouakader2006/ISOHub
# Version     : 1.0
# Created     : 2026
# Description : Open Source ISO Downloader
#
# Features
# - Download Linux ISO images
# - SHA256 verification
# - Download history
# - Windows Forms GUI
# - Open Source
#
# Copyright (c) 2026 Abdelkader Nouacer
# Released under the MIT License
# =======================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DataPath      = Join-Path $ScriptRoot "data"
$ToolsPath     = Join-Path $ScriptRoot "tools"
$AssetsPath    = Join-Path $ScriptRoot "Assets"
Copy-Item .\ISOHub.ps1 .\ISOHub_Backup.ps1
# =======================================
# Global Variables
# =======================================

$Global:CurrentDownload = $null
$Global:CancelRequested = $false
$Global:DownloadJob = $null
$Global:IsDownloading = $false

# =======================================
# Get List
# =======================================

function Get-ISOList {

    $JsonUrl = "https://raw.githubusercontent.com/nouakader2006/ISOHub/main/data/os.json"

    try {

        return Invoke-RestMethod -Uri $JsonUrl

    }
    catch {

        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "ISOHub Error"
        )

        return $null
    }
}
$OSList = Get-ISOList
$OSList.Count

# =======================================
# Update List
# =======================================
function Update-OSList {

    $listBox.Items.Clear()

    if ($cmbCategory.SelectedItem -eq "All")
    {
        $script:FilteredOSList = $script:OSList
    }
    else
    {
        $script:FilteredOSList = $script:OSList |
            Where-Object Category -eq $cmbCategory.SelectedItem
    }

    foreach ($OS in $script:FilteredOSList)
    {
        [void]$listBox.Items.Add($OS.Name)
    }
}

# =======================================
# SHA256
# =======================================

function Get-SHA256Hash
{
    param(
        [string]$FilePath
    )

    if (Test-Path $FilePath)
    {
        return (
            Get-FileHash `
                -Path $FilePath `
                -Algorithm SHA256
        ).Hash.ToUpper()
    }

    return $null
}



# =======================================
# Folders
# =======================================

$RootFolder = "C:\ISOHub"
$DownloadFolder = "$RootFolder\Downloads"
$HistoryFolder = "$RootFolder\History"


foreach($Folder in @($RootFolder,$DownloadFolder,$HistoryFolder))
{
    if(!(Test-Path $Folder))
    {
        New-Item `
            -Path $Folder `
            -ItemType Directory `
            -Force | Out-Null
    }
}

# =======================================
# Generate README.md
# =======================================

$ReadmeFile = Join-Path $RootFolder "README.md"

if (!(Test-Path $ReadmeFile))
{
    @"
# ISOHub

ISOHub is an open-source Windows PowerShell application for downloading operating system ISO images.

## Features

- Ubuntu Downloads
- Kali Linux Downloads
- Debian Downloads
- SHA256 Verification
- Download History
- Simple Graphical Interface
- Open Source

## Author

Abdelkader Nouacer

GitHub:
https://github.com/nouakader2006/ISOHub

## License

MIT License

## Version

1.0
"@ | Set-Content `
    -Path $ReadmeFile `
    -Encoding UTF8
}
# =======================================
# Load Catalog
# =======================================

$OSList = Get-Content (Join-Path $ScriptRoot "data\os.json") -Raw | ConvertFrom-Json



# =======================================
# Main Window
# =======================================

$form = New-Object System.Windows.Forms.Form
$form.BackColor =[System.Drawing.Color]::FromArgb(240,244,249)
$form.Text = "ISOHub v1.0 - Open Source ISO Downloader"
$form.Size = New-Object System.Drawing.Size(1000,650)
$form.StartPosition = "CenterScreen"

# =======================================
# ComboBox
# =======================================
$cmbCategory = New-Object System.Windows.Forms.ComboBox
$cmbCategory.Location = New-Object System.Drawing.Point(15,25)
$cmbCategory.Size = New-Object System.Drawing.Size(300,25)
$cmbCategory.DropDownStyle = "DropDownList"
$cmbCategory.Items.Add("All")
$cmbCategory.Items.Add("Linux")
$cmbCategory.Items.Add("Windows")
$cmbCategory.Items.Add("Utility")
$cmbCategory.SelectedIndex = 0
$form.Controls.Add($cmbCategory)
$cmbCategory.Add_SelectedIndexChanged({

    Update-OSList

})
# =======================================
# ISO List
# =======================================
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.BackColor =[System.Drawing.Color]::White
$listBox.Location = New-Object System.Drawing.Point(15,55)
$listBox.Size = New-Object System.Drawing.Size(300,400)

foreach($OS in $OSList)
{
    $listBox.Items.Add($OS.Name)
}


# =======================================
# Information Panel
# =======================================

$txtInfo = New-Object System.Windows.Forms.TextBox
$txtInfo.BackColor =[System.Drawing.Color]::White 
$txtInfo.ForeColor = [System.Drawing.Color]::Black
$txtInfo.Location = New-Object System.Drawing.Point(340,20)
$txtInfo.Size = New-Object System.Drawing.Size(350,250)
$txtInfo.Multiline = $true
$txtInfo.ReadOnly = $true
$txtInfo.ScrollBars = "Vertical"

# =======================================
# Download Button
# =======================================

$btnDownload = New-Object System.Windows.Forms.Button
[System.Drawing.Color]::FromArgb(0,120,212)
$btnDownload.Text = "Download"
$btnDownload.Location = New-Object System.Drawing.Point(720,20)
$btnDownload.Size = New-Object System.Drawing.Size(200,50)

# =======================================
# Cancel Button
# =======================================

$btnCancel = New-Object System.Windows.Forms.Button
[System.Drawing.Color]::FromArgb(0,120,212)
$btnCancel.Text = "Cancel"
$btnCancel.Location = New-Object System.Drawing.Point(720,160)
$btnCancel.Size = New-Object System.Drawing.Size(200,50)
$btnCancel.Enabled = $false

# =======================================
# Open Downloads Button
# =======================================

$btnFolder = New-Object System.Windows.Forms.Button
[System.Drawing.Color]::FromArgb(0,120,212)
$btnFolder.Text = "Open Downloads"
$btnFolder.Location = New-Object System.Drawing.Point(720,90)
$btnFolder.Size = New-Object System.Drawing.Size(200,50)

# =======================================
# Update Catalog
# =======================================
$btnUpdateCatalog = New-Object System.Windows.Forms.Button
[System.Drawing.Color]::FromArgb(0,120,212)
$btnUpdateCatalog.Text = "Update Catalog"
$btnUpdateCatalog.Location = New-Object System.Drawing.Point(720,230)
$btnUpdateCatalog.Size = New-Object System.Drawing.Size(200,50)

# =======================================
# test Link
# =======================================
$btnTestLinks = New-Object System.Windows.Forms.Button
[System.Drawing.Color]::FromArgb(0,120,212)
$btnTestLinks.Text = "Test Links"
$btnTestLinks.Location = New-Object System.Drawing.Point(720,300)
$btnTestLinks.Size = New-Object System.Drawing.Size(200,50)
# =======================================
# label Ready
# =======================================
$lblAuthor = New-Object System.Windows.Forms.Label
$lblAuthor.Location = New-Object System.Drawing.Point(20,600)
$lblAuthor.Size = New-Object System.Drawing.Size(500,20)
$lblAuthor.Text = "ISOHub v1.0 - Created by Abdelkader Nouacer"

# =======================================
# Progress Bar
# =======================================

$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(20,540)
$ProgressBar.Size = New-Object System.Drawing.Size(900,25)
$ProgressBar.Style = "Blocks"

# =======================================
# Status Label
# =======================================

$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(20,570)
$status.Size = New-Object System.Drawing.Size(900,30)
$status.Text = "Ready"

# =======================================
# Background
# =======================================
$BackgroundPath = Join-Path $AssetsPath "Logo.png"
$picBackground = New-Object System.Windows.Forms.PictureBox
$picBackground.Image = [System.Drawing.Image]::FromFile($BackgroundPath)
$picBackground.BackColor = [System.Drawing.Color]::Transparent
$picBackground.SizeMode = "Zoom"
$picBackground.Location = New-Object System.Drawing.Point(320,280)
$picBackground.Size = New-Object System.Drawing.Size(300,200)
$picBackground.Enabled = $false
$Form.Controls.Add($picBackground)
$picBackground.SendToBack()

# =======================================
# ISO Selection
# =======================================

$listBox.Add_SelectedIndexChanged({

    if($listBox.SelectedIndex -ge 0)
    {
        $SelectedOS = $script:FilteredOSList[$listBox.SelectedIndex]

        $txtInfo.Text = @"
Name          : $($SelectedOS.Name)
Version       : $($SelectedOS.Version)
Category      : $($SelectedOS.Type)
Architecture  : $($SelectedOS.Architecture)
File Name     : $($SelectedOS.FileName)
Vendor        : $($SelectedOS.Vendor)
Size          : $($SelectedOS.Size)
"@
    }
})

# =======================================
# Download
# =======================================
$btnDownload.Add_Click({

    if ($Global:IsDownloading)
    {
        $status.Text = "A download is already running."
        return
    }

    if ($listBox.SelectedIndex -lt 0)
    {
        $status.Text = "Please select an ISO image."
        return
    }

    try
    {
        $SelectedOS = $script:FilteredOSList[$listBox.SelectedIndex]

        if ([string]::IsNullOrWhiteSpace($SelectedOS.Url))
        {
            $status.Text = "Download URL not found."
            return
        }
    
        if (-not $SelectedOS.Url.StartsWith("https://"))
        {
            $status.Text = "Only HTTPS URLs are allowed."
            return
        }

        
            $Destination = Join-Path `
            $DownloadFolder `
            $SelectedOS.FileName

        if (Test-Path $Destination)
        {
            $Answer =
            [System.Windows.Forms.MessageBox]::Show(
                "The file already exists. Overwrite it ?",
                "ISOHub",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($Answer -ne "Yes")
            {
                return
            }

            Remove-Item $Destination -Force
        }
    
        $Global:CurrentDownload = $Destination
        $Global:IsDownloading = $true

        $btnDownload.Enabled = $false
        $btnCancel.Enabled = $true

        $ProgressBar.Style = "Marquee"

        $status.Text =
        "Downloading $($SelectedOS.Name)..."

        $Global:DownloadJob = Start-Job `
            -ArgumentList $SelectedOS.Url,$Destination `
            -ScriptBlock {

                param($Url,$Destination)

                Invoke-WebRequest `
                    -Uri $Url `
                    -OutFile $Destination
            }

        $script:DownloadTimer = New-Object System.Windows.Forms.Timer
        $script:DownloadTimer.Interval = 1000

        $script:DownloadTimer.Add_Tick({

    if (-not $Global:DownloadJob)
    {
        return
    }

    if ($Global:DownloadJob.State -eq "Completed")
    {
        $script:DownloadTimer.Stop()

        $ProgressBar.Style = "Blocks"
        $ProgressBar.Value = 100

        $ActualHash = Get-SHA256Hash $Global:CurrentDownload

        $Verified = $false

        if (
            $SelectedOS.SHA256 -and
            $SelectedOS.SHA256.Trim() -ne ""
        )
        {
            $Verified = (
                $ActualHash -eq $SelectedOS.SHA256.ToUpper()
            )
        }

        if (
            $SelectedOS.SHA256 -and
            $SelectedOS.SHA256.Trim() -ne "" -and
            $SelectedOS.SHA256.ToUpper() -ne $ActualHash
        )
        {
            $status.Text =
            "WARNING : SHA256 verification failed"

            [System.Windows.Forms.MessageBox]::Show(
                "Hash verification failed.",
                "Security Warning"
            )
        }
        else
        {
            $status.Text =
            "Download completed."
        }

        $HistoryFile = Join-Path `
            $HistoryFolder `
            "downloads.csv"

        [PSCustomObject]@{
            Date       = Get-Date
            Name       = $SelectedOS.Name
            Version    = $SelectedOS.Version
            File       = $SelectedOS.FileName
            SHA256     = $ActualHash
            Verified   = $Verified
        } |
        Export-Csv `
            -Path $HistoryFile `
            -Append `
            -NoTypeInformation `
            -Force

        Remove-Job `
            $Global:DownloadJob `
            -Force `
            -ErrorAction SilentlyContinue

        $Global:DownloadJob = $null
        $Global:IsDownloading = $false

        $btnDownload.Enabled = $true
        $btnCancel.Enabled = $false
    }

    elseif ($Global:DownloadJob.State -eq "Failed")
    {
        $Script:DownloadTimer.Stop()

        $ProgressBar.Style = "Blocks"
        $ProgressBar.Value = 0

        $status.Text = "Download failed."

        Remove-Job `
            $Global:DownloadJob `
            -Force `
            -ErrorAction SilentlyContinue

        $Global:DownloadJob = $null
        $Global:IsDownloading = $false

        $btnDownload.Enabled = $true
        $btnCancel.Enabled = $false
    }

    elseif ($Global:DownloadJob.State -eq "Stopped")
    {
        $Script:DownloadTimer.Stop()

        $ProgressBar.Style = "Blocks"
        $ProgressBar.Value = 0

        $status.Text = "Download cancelled."

        $Global:DownloadJob = $null
        $Global:IsDownloading = $false

        $btnDownload.Enabled = $true
        $btnCancel.Enabled = $false
    }
     })

        $Script:DownloadTimer.Start()
    }   
    catch
    {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "ISOHub Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}
    )
# =======================================
# Open Folder
# =======================================
$btnFolder.Add_Click({

    if (!(Test-Path $DownloadFolder))
    {
        New-Item `
            -ItemType Directory `
            -Path $DownloadFolder | Out-Null
    }

    Invoke-Item $DownloadFolder

})
# =======================================
# Update Catalog
# =======================================
$btnUpdateCatalog.Add_Click({

    $Ubuntu = $script:OSList | Where-Object Name -eq "Ubuntu"
    $Kali   = $script:OSList | Where-Object Name -eq "Kali"
    $Debian = $script:OSList | Where-Object Name -eq "Debian"
    $Windows11 = $script:OSList | Where-Object Name -eq "Windows 11"
    $Windows10 = $script:OSList | Where-Object Name -eq "Windows 10"
    $Rufus = $Script:OSList | Where-Object Name -eq "Rufus"
    $Ventoy = $Script:OSList | Where-Object Name -eq "Ventoy"
    $EtcherBalena = $Script:OSList | Where-Object Name -eq "Etcher Balena"
    try
    {
       $UpdateScript = Join-Path $ToolsPath "Update-Catalog.ps1"

        if (!(Test-Path $UpdateScript))
        {
            throw "Update-Catalog.ps1 not found:`n$UpdateScript"
        }

        & $UpdateScript

        $status.Text = "Catalog updated successfully."

        $script:OSList = Get-Content (Join-Path $DataPath "os.json") -Raw |
         ConvertFrom-Json

        $listBox.Items.Clear()

           Update-OSList

        
    }
    catch
    {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "ISOHub Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }

    $UpdateForm = New-Object System.Windows.Forms.Form
    $UpdateForm.Text = "ISOHub - Catalog Update"
    $UpdateForm.Size = New-Object System.Drawing.Size(500,300)
    $UpdateForm.StartPosition = "CenterParent"
    $UpdateForm.BackColor = [System.Drawing.Color]::Honeydew
    $txtResult = New-Object System.Windows.Forms.TextBox
    $txtResult.Multiline = $true
    $txtResult.ReadOnly = $true
    $txtResult.ScrollBars = "Vertical"
    $txtResult.Location = New-Object System.Drawing.Point(10,10)
    $txtResult.Size = New-Object System.Drawing.Size(460,200)
    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $txtResult.Text = @"
    Catalog updated successfully
    $Date

    Ubuntu : $($Ubuntu.Version)
    Kali   : $($Kali.Version)
    Debian : $($Debian.Version)
    Windows11: $($Windows11.version)
    Windows10: $($Windows10.version)
    Rufus: $($Rufus.version)
    Ventoy: $($Ventoy.version)
    Etcher Balena: $($EtcherBalena.version)

    Entries : $($script:OSList.Count)
"@
    $txtResult.Font = New-Object System.Drawing.Font("Consolas",10)

    $UpdateForm.Controls.Add($txtResult)

    # Bouton Close
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Size = New-Object System.Drawing.Size(100,30)
    $btnClose.Location = New-Object System.Drawing.Point(185,220)

    $btnClose.Add_Click({
        $UpdateForm.Close()
    })

    $UpdateForm.Controls.Add($btnClose)

    $UpdateForm.AcceptButton = $btnClose

    # Afficher la fenêtre EN DERNIER
    [void]$UpdateForm.ShowDialog()    
})
# =======================================
# Test Link
# =======================================
function Show-LinkTestWindow {

    $TestForm = New-Object System.Windows.Forms.Form
    $TestForm.Text = "ISOHub - Link Tester"
    $TestForm.Size = New-Object System.Drawing.Size(700,500)
    $TestForm.StartPosition = "CenterParent"

    $txtResults = New-Object System.Windows.Forms.TextBox
    $txtResults.Multiline = $true
    $txtResults.ReadOnly = $true
    $txtResults.ScrollBars = "Vertical"
    $txtResults.Dock = "Fill"

    $TestForm.Controls.Add($txtResults)

    $OSList = Get-Content (Join-Path $DataPath "os.json") -Raw |ConvertFrom-Json

    foreach($OS in $OSList)
    {
        $txtResults.AppendText(
            "Testing $($OS.Name)...`r`n"
        )

        try
        {
            $Request = [System.Net.WebRequest]::Create(
                $OS.Url
            )

            $Request.Timeout = 10000

            $Response = $Request.GetResponse()

            $txtResults.AppendText(
                "OK`r`n`r`n"
            )

            $Response.Close()
        }
        catch
        {
            $txtResults.AppendText(
                "FAILED : $($_.Exception.Message)`r`n`r`n"
            )
        }

        [System.Windows.Forms.Application]::DoEvents()
    }

    $txtResults.AppendText(
        "=========`r`nTest completed."
    )

    $TestForm.ShowDialog()
}

$btnTestLinks.Add_Click({
Show-LinkTestWindow
})
# =======================================
# Add Controls
# =======================================

$form.Controls.Add($listBox)
$form.Controls.Add($txtInfo)
$form.Controls.Add($btnDownload)
$form.Controls.Add($btnFolder)
$form.Controls.Add($btnUpdateCatalog)
$form.Controls.Add($btnCancel)
$form.Controls.Add($btnTestLinks)
$form.Controls.Add($ProgressBar)
$form.Controls.Add($status)
$form.Controls.Add($lblAuthor)

# =======================================
# Start Application
# =======================================

[void]$form.ShowDialog()
