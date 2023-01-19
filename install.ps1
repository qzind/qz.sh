#!/usr/bin/env pwsh

<#
.SYNOPSIS
    QZ Tray installer, for PowerShell
.DESCRIPTION
    This script was downloaded from https://github.com/qzind/qz.sh and is part of the QZ Tray product
    Contribute to this script by visting the above website and opening an issue or pull request
.PARAMETER param1
    Specifies QZ Tray version to install
    Can be "stable", "beta" or "v2.2.1"
.LINK
    https://github.com/qzind/qz.sh
#>
param(
    [String] $param1
)

$OWNER="qzind"
$REPO="tray"
$URL="https://api.github.com/repos/${OWNER}/${REPO}/releases?per_page=100"
$SCRIPT_NAME="pwsh.sh"

$RELEASE="auto"  # e.g. "stable", "unstable"
$TAG="auto"      # e.g. "2.2.1", "v2.1.6"

if($param1) {
    Write-Host "Picked up argument: " -NoNewline
    Write-Host "$param1" -ForegroundColor Blue

    switch -Regex ($param1) {
        ".*help" {
            $SCRIPT="irm $SCRIPT_NAME | iex"
            # Determine if running from a pipe or not
            if($MyInvocation.MyCommand.Definition -contains ".ps1") {
                $SCRIPT=Split-Path $MyInvocation.MyCommand.Definition -leaf
            }
            
            Write-Host "`nUsage:`n  $SCRIPT [`"" -NoNewline
            Write-Host                         "stable" -ForegroundColor Green -NoNewline
            Write-Host                                "|`"" -NoNewline
            Write-Host                                   "beta" -ForegroundColor Yellow -NoNewline
            Write-Host                                        "`"|<" -NoNewline
            Write-Host                                             "version" -ForegroundColor Blue -NoNewline
            Write-Host                                                     ">|`"" -NoNewline
            Write-host                                                          "help" -ForegroundColor Magenta -NoNewline
            Write-Host "`"]"
            
            Write-Host "    stable  " -ForegroundColor Green -NoNewline
            Write-Host              "   Downloads and installs the latest stable release"

            Write-Host "    beta    " -ForegroundColor Yellow -NoNewline
            Write-Host              "   Downloads and installs the latest beta release"

            Write-Host "    version " -ForegroundColor Blue -NoNewline
            Write-Host              "   Downloads and installs the exact version specified, e.g. `"2.2.1`""

            Write-Host "    help    " -ForegroundColor Magenta -NoNewline
            Write-Host              "   Displays this help and exits"

            Write-Host "`n  The default behavior is to download and install the " -NoNewline
            Write-Host                                                          "stable" -ForegroundColor Green -NoNewline
            Write-Host                                                                 " version`n"

            exit 0
        }
        "stable" {
            $RELEASE="stable"
        }
        "unstable" {
            $RELEASE="beta"
        }
        "beta" {
            $RELEASE="beta"
        }
    }

    # If a parameter was provided but we don't recognize it, treat it as a tag
    if("$RELEASE" -eq "auto" ) {
        $TAG="$param1"
        # Append "v" to version if missing (e.g. 2.2.1 vs v2.2.1)
        if($TAG.Substring(0, 1) -ne "v") {
           $TAG="v${TAG}"
        }
    }
}



# Determine architecture
# valid values: "amd64", "arm64", "riscv"

# Windows
if($Env:OS -and "$Env:OS".Substring(0, 3) -like "Win*") {
    if("${Env:ProgramFiles(Arm)}" -ne "") {
        # PowerShell on Windows ARM64 is very common to be running under emulation
        # trust "ProgramFiles(Arm)" first
        $ARCH="arm64"
    } else {
        switch("$Env:PROCESSOR_ARCHITECTURE") {
            "ARM64" {
                $ARCH="arm64"
                break
            }
            "x86" {
                Write-Host "WARNING: 32-bit platforms are unsupported"
            }
            default {
                $ARCH="amd64"
            }
        }
    }
}
# Unix/Linux
else {
    $ARCH=(uname -m)
    switch -Regex ($ARCH) {
        ".*arm64.*" {
            $ARCH="arm64"
            break
        }
        ".*aarch64.*" {
            $ARCH="arm64"
            break
        }
        ".*riscv.*" {
            $ARCH="riscv"
            break
        }
        default {
            $ARCH="amd64"
        }
    }
}

# Determine file extension
# valid values: ".run", ".pkg", ".exe"
$EXTENSION=".exe"
if($Env:OS -and "$Env:OS".Substring(0, 3) -like "Win*") {
    # Do nothing
} else {
    if($IsMacOS) {
        $EXTENSION=".pkg"
    } else {
        $EXTENSION=".run"
    }
}

if("$RELEASE" -eq "auto" ) {
    $RELEASE="stable"
}

Write-Host "Parsing " -NoNewline
Write-Host          "$URL" -ForegroundColor Blue -NoNewline
Write-Host               "... "
$jsonData = Invoke-RestMethod -Uri "$URL"

# Gather stable and beta tagged releases by loop over JSON returned from GitHub API
if("$TAG" -eq "auto") {
    $STABLE_TAGS=@()
    $BETA_TAGS=@()

    $tag_name=""

    foreach($item in $jsonData) {
        $BETA_TAGS += $item.tag_name
        if(-Not $item.prerelease) {
            $STABLE_TAGS += $item.tag_name
        }
    }

    # Sort the results
    $LATEST_STABLE = $STABLE_TAGS | Sort-Object -Descending | Select-Object -First 1
    $LATEST_BETA = $BETA_TAGS | Sort-Object -Descending | Select-Object -First 1

    switch($RELEASE) {
        "stable" {
            $TAG="$LATEST_STABLE"
            break
        }
        "beta" {
            $TAG="$LATEST_BETA"
            break
        }
    }

    if("$TAG" -eq "") {
        Write-Host "Unable to locate a tag for this release" -ForegroundColor Red
        exit 2
    }

    Write-Host "Latest " -NoNewline
    Write-Host         "$RELEASE" -ForegroundColor Green -NoNewline
    Write-Host                  " version found: " -NoNewline
    Write-Host                                   "$TAG" -ForegroundColor Blue
}

# Get URL for latest release
Write-Host "Searching " -NoNewline
Write-Host            "${EXTENSION}" -ForegroundColor Blue -NoNewline
Write-Host                         " downloads for " -NoNewline
Write-Host                                         "${TAG}" -ForegroundColor Blue -NoNewline
Write-Host                                                " matching " -NoNewline
Write-Host                                                           "${ARCH}" -ForegroundColor Blue -NoNewline
Write-Host                                                                   "..."

$OS_URLS=@()
foreach($item in $jsonData) {
    if($item.tag_name -eq $TAG) {
        foreach($asset in $item.assets) {
            if($asset.browser_download_url.EndsWith($EXTENSION)) {
                $OS_URLS += $asset.browser_download_url
            }
        }
    }
}

# Gather all URLs that match current architecture
$AMD64_URLS=@()
$ARM64_URLS=@()
$RISCV_URLS=@()
foreach($url in $OS_URLS) {
    switch -Regex ($url) {
        ".*arm64.*" {
            $ARM64_URLS += $url
            break
        }
        ".*riscv.*" {
            $RISCV_URLS += $url
            break
        }
        default {
            $AMD64_URLS += $url
        }
    }
}

# Echo the proper download URL
$DOWNLOAD_URL=""
switch -Regex ($arch) {
    ".*arm64.*" {
        $DOWNLOAD_URL = $ARM64_URLS | Select-Object -First 1
        break;
    }
    ".*riscv.*" {
        $DOWNLOAD_URL = $RISCV_URLS | Select-Object -First 1
        break;
    }
    default {
        $DOWNLOAD_URL = $AMD64_URLS | Select-Object -First 1
    }
}

if ("$DOWNLOAD_URL" -eq "") {
    Write-Host "Unable to locate a download for this platform" -ForegroundColor Red
    exit 2
}

Write-Host "Downloading " -NoNewline
Write-Host              "${DOWNLOAD_URL}" -ForegroundColor Blue -NoNewline
Write-Host                              "..."

if($env:TEMP) {
    # Windows
    $TEMP_FILE = "$env:TEMP\${REPO}-${TAG}${EXTENSION}"
} else {
    $TEMP_FILE="/tmp/${REPO}-${TAG}${EXTENSION}"
}

# Remove old copy if needed
if (Test-Path -Path "$TEMP_FILE") {
    Remove-Item -fo "$TEMP_FILE"
}

# Download the file
Invoke-WebRequest "$DOWNLOAD_URL" -OutFile "$TEMP_FILE"

# Install using unattended techniques: https://github.com/qzind/tray/wiki/deployment
Write-Host "Download successful, beginning the install..."

switch($EXTENSION) {
    ".pkg" {
        sudo installer -pkg "$TEMP_FILE" -target /
        break
    }
    ".run" {
        if (Get-Command "sudo" -errorAction SilentlyContinue) {
            sudo bash "$TEMP_FILE" --nox11 -- -y
        } else {
            # fallback to "su -c"
            su root -c "bash '$TEMP_FILE' --nox11 -- -y"
        }
        break
    }
    default {
        # assume .exe
        Start-Process "$TEMP_FILE" -ArgumentList "/S" -Verb RunAs -Wait
    }

}

# Clean up
Remove-Item -fo "$TEMP_FILE"
exit 0
