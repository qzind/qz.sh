#!/usr/bin/env bash

set -e

# This script was downloaded from https://github.com/qzind/qz.sh and is part of the QZ Tray product
# Contribute to this script by visting the above website and opening an issue or pull request

# Console colors
RED="\\x1B[1;31m";GREEN="\\x1B[1;32m";BLUE="\\x1B[1;34m";PURPLE="\\x1B[1;35m";YELLOW="\\x1B[1;33m";PLAIN="\\x1B[0m"

OWNER="qzind"
REPO="tray"
URL="https://api.github.com/repos/${OWNER}/${REPO}/releases?per_page=100"

FETCH=""
# Determine if curl or wget are available
if which curl >/dev/null 2>&1 ; then
    FETCH="curl -Ls"
elif which wget >/dev/null 2>&1 ; then
    FETCH="wget -q -O -"
else
    echo -e "${RED}Either \"curl\" or \"wget\" are required to use this script${PLAIN}"
    exit 2
fi

RELEASE="auto"  # e.g. "stable", "unstable"
TAG="auto"      # e.g. "2.2.1", "v2.1.6"
if [ ! -z "$1" ]; then
    echo -e "Picked up argument: ${BLUE}$1${PLAIN}"
    case $1 in
    *"help")
        SCRIPT="$FETCH qz.sh |bash -s --"
        if [ -t 0 ]; then
            SCRIPT="install.sh"
        fi
        echo -e "\nUsage:\n  $SCRIPT [\"${GREEN}stable${PLAIN}\"|\"${YELLOW}beta${PLAIN}\"|<${BLUE}version${PLAIN}>|\"${PURPLE}help${PLAIN}\"]"
        echo -e "    ${GREEN}stable${PLAIN}   Downloads and installs the latest stable release"
        echo -e "    ${YELLOW}beta${PLAIN}     Downloads and installs the latest beta release"
        echo -e "    ${BLUE}version${PLAIN}  Downloads and installs the exact version specified, e.g. \"2.2.1\""
        echo -e "    ${PURPLE}help${PLAIN}     Displays this help and exits"
        echo -e "\n  The default behavior is to download and install the ${GREEN}stable${PLAIN} version\n"
        exit 0
        ;;
    "stable")
        RELEASE="stable"
        ;;
    "beta")
        RELEASE="beta"
        ;;
    "unstable")
        RELEASE="beta"
        ;;
    esac
    # If a parameter was provided but we don't recognize it, treat it as a tag
    if [ "$RELEASE" == "auto" ]; then
        TAG="$1"
        # Append "v" to version if missing (e.g. 2.2.1 vs v2.2.1)
        first_char="$(echo "$TAG"| cut -c1)"
        if [ "$first_char" != "v" ]; then
            TAG="v${TAG}"
        fi
    fi
fi

# Determine architecture
# valid values: "amd64", "arm64", "riscv"
ARCH="$(uname -m)"
case $ARCH in
    *"arm64"*)
        ARCH="arm64"
        ;;
    *"aarch64"*)
        ARCH="arm64"
        ;;
    *"riscv"*)
        ARCH="riscv"
        ;;
    *)
        ARCH="amd64"
        ;;
esac

# Determine file extension
# valid values: ".run", ".pkg", ".exe"
EXTENSION=".run"
case $OSTYPE in
"darwin"*)
    EXTENSION=".pkg"
    ;;
esac

if [ "$RELEASE" == "auto" ]; then
    RELEASE="stable"
fi

echo -e "Parsing ${BLUE}${URL}${PLAIN}..."
JSON="$($FETCH "$URL")"

# Gather stable and beta tagged releases by loop over JSON returned from GitHub API
if [ "$TAG" == "auto" ]; then
    STABLE_TAGS=""
    BETA_TAGS=""

    tag_name=""
    while IFS= read -r line; do
        case $line in
            *"\"tag_name\":"*)
                # assume "tag_name": comes before "prerelease":
                tag_name="$(echo "$line" |cut -d '"' -f4 |tr -d '"'|tr -d ',' |tr -d ' ')"
                ;;
            *"\"prerelease\": false,"*)
                STABLE_TAGS+="$tag_name"$'\n'
                ;;
            *"\"prerelease\": true,"*)
                BETA_TAGS+="$tag_name"$'\n'
                ;;
            *"\"assets\":"*)
                # we've gone too far
                tag_name=""
                ;;
        esac
    done <<< "$JSON"

    # Sort the results
    LATEST_STABLE="$(echo "${STABLE_TAGS}" |sort -Vr|head -1)"
    LATEST_BETA="$(echo "${BETA_TAGS}" |sort -Vr|head -1)"

    case $RELEASE in
        "stable")
            TAG="$LATEST_STABLE"
            ;;
        "beta")
            TAG="$LATEST_BETA"
            ;;
    esac

    if [ -z "$TAG" ]; then
        echo -e "${RED}Unable to locate a tag for this release${PLAIN}"
        exit 2
    fi

    echo -e "Latest ${GREEN}${RELEASE}${PLAIN} version found: ${BLUE}$TAG${PLAIN}"
fi

# Get URL for latest release
echo -e "Searching ${BLUE}${EXTENSION}${PLAIN} downloads for ${BLUE}${TAG}${PLAIN} matching ${BLUE}${ARCH}${PLAIN}..."
OS_URLS=""
while IFS= read -r line; do
    url=""
    case $line in
        *"download/$TAG/"*)
            url=$(echo "$line" |cut -d '"' -f4 |tr -d '"'|tr -d ',' |tr -d ' ')
            ;;
    esac
    case $url in
        *"$EXTENSION")
            OS_URLS+="$url"$'\n'
            ;;
    esac
done <<< "$JSON"

# Gather all URLs that match current architecture
AMD64_URLS=""
ARM64_URLS=""
RISCV_URLS=""
while IFS= read -r line; do
    url=""
    case $line in
        *"arm64"*)
            ARM64_URLS+="$line"$'\n'
            ;;
        *"riscv"*)
            RISCV_URLS+="$line"$'\n'
            ;;
        *)
            AMD64_URLS+="$line"$'\n'
            ;;
    esac
done <<< "$OS_URLS"

# Echo the proper download URL
DOWNLOAD_URL=""
case $ARCH in
    *"arm64"*)
        DOWNLOAD_URL=$(echo "$ARM64_URLS" |head -1)
        ;;
    *"riscv"*)
        DOWNLOAD_URL=$(echo "$RISCV_URLS" |head -1)
        ;;
    *)
        DOWNLOAD_URL=$(echo "$AMD64_URLS" |head -1)
        ;;

esac

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Unable to locate a download for this platform${PLAIN}"
    exit 2
fi

echo -e "Downloading ${BLUE}${DOWNLOAD_URL}${PLAIN}..."

# Determine if curl or wget are available
TEMP_FILE="/tmp/${REPO}-${TAG}${EXTENSION}"

# Remove old copy if needed
if [ -f "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE" >/dev/null
fi

# Download installer using curl or wget
if which curl >/dev/null 2>&1 ; then
    # Note: GitHub uses redirects, make sure "curl -L" is specifed
    curl -Ls "$DOWNLOAD_URL" --output "/tmp/${REPO}-${TAG}${EXTENSION}"
elif which wget >/dev/null 2>&1 ; then
    # Note: GitHub uses redirects, but wget should follow redirects automatically
    wget -q -O $TEMP_FILE "$DOWNLOAD_URL"
else
    echo -e "${RED}Either \"curl\" or \"wget\" are required to use this script${PLAIN}"
    exit 2
fi

# Install using unattended techniques: https://github.com/qzind/tray/wiki/deployment
echo -e "Download successful, beginning the install..."
case $OSTYPE in
    "darwin"*)
        # Assume .pkg (installer) for MacOS
        sudo installer -pkg "$TEMP_FILE" -target /
        ;;
    *)
        # Assume .run (makeself) for others
        if which sudo >/dev/null 2>&1 ; then
            # use "sudo" if available
            sudo bash "$TEMP_FILE" --nox11 -- -y
        else
            # fallback to "su -c"
            su root -c "bash '$TEMP_FILE' --nox11 -- -y"
        fi
        ;;
esac

# Clean up
rm -f "$TEMP_FILE" >/dev/null
exit 0
