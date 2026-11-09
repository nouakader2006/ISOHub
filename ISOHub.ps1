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

$OSList = Get-Content ".\data\os.json" -Raw | ConvertFrom-Json
Remove-Item "C:\ISOHub\History\downloads.csv"


# =======================================
# Main Window
# =======================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "ISOHub v1.0 - Open Source ISO Downloader"
$form.Size = New-Object System.Drawing.Size(1000,650)
$form.StartPosition = "CenterScreen"

# =======================================
# ISO List
# =======================================

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,20)
$listBox.Size = New-Object System.Drawing.Size(300,500)

foreach($OS in $OSList)
{
    $listBox.Items.Add($OS.Name)
}

# =======================================
# Information Panel
# =======================================

$txtInfo = New-Object System.Windows.Forms.TextBox
$txtInfo.Location = New-Object System.Drawing.Point(340,20)
$txtInfo.Size = New-Object System.Drawing.Size(350,250)
$txtInfo.Multiline = $true
$txtInfo.ReadOnly = $true
$txtInfo.ScrollBars = "Vertical"

# =======================================
# Download Button
# =======================================

$btnDownload = New-Object System.Windows.Forms.Button
$btnDownload.Text = "Download"
$btnDownload.Location = New-Object System.Drawing.Point(720,20)
$btnDownload.Size = New-Object System.Drawing.Size(200,50)

# =======================================
# Cancel Button
# =======================================

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Location = New-Object System.Drawing.Point(720,160)
$btnCancel.Size = New-Object System.Drawing.Size(200,50)
$btnCancel.Enabled = $false

# =======================================
# Open Downloads Button
# =======================================

$btnFolder = New-Object System.Windows.Forms.Button
$btnFolder.Text = "Open Downloads"
$btnFolder.Location = New-Object System.Drawing.Point(720,90)
$btnFolder.Size = New-Object System.Drawing.Size(200,50)
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
# ISO Selection
# =======================================

$listBox.Add_SelectedIndexChanged({

    if($listBox.SelectedIndex -ge 0)
    {
        $SelectedOS = $OSList[$listBox.SelectedIndex]

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
        $SelectedOS = $OSList[$listBox.SelectedIndex]

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

$btnFolder.Add_Click({

    try
    {
        if (Test-Path $DownloadFolder)
        {
            Start-Process explorer.exe `
                -ArgumentList "`"$DownloadFolder`""
        }
        else
        {
            [System.Windows.Forms.MessageBox]::Show(
                "Download folder not found:`n$DownloadFolder",
                "ISOHub"
            )
        }
    }
    catch
    {
        [System.Windows.Forms.MessageBox]::Show(
            $_.Exception.Message,
            "ISOHub Error"
        )
    }

})
# =======================================
# Add Controls
# =======================================

$form.Controls.Add($listBox)
$form.Controls.Add($txtInfo)
$form.Controls.Add($btnDownload)
$form.Controls.Add($btnFolder)
$form.Controls.Add($btnCancel)
$form.Controls.Add($ProgressBar)
$form.Controls.Add($status)
$form.Controls.Add($lblAuthor)

# =======================================
# Start Application
# =======================================

[void]$form.ShowDialog()
