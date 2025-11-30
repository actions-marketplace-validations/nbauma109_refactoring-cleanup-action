#!/bin/bash
set -euo pipefail

# --------------------------------------------------------------------
# Parameters
#   $1 = Eclipse version   (example: 2025-09)
#   $2 = Eclipse package   (example: java, jee)
# --------------------------------------------------------------------

VERSION="$1"
PACKAGE="$2"

# Eclipse official EPP archive location
BASE_URL="https://www.eclipse.org/downloads/download.php"
FILE_PATH="/technology/epp/downloads/release/${VERSION}/R/eclipse-${PACKAGE}-${VERSION}-R-linux-gtk-x86_64.tar.gz"
URL="${BASE_URL}?file=${FILE_PATH}&r=1"

echo "Downloading Eclipse:"
echo "  ${URL}"

curl -L "$URL" -o /tmp/eclipse.tar.gz

mkdir -p /opt/eclipse
tar -xf /tmp/eclipse.tar.gz -C /opt

# Find extracted Eclipse dir (eclipse, eclipse-java-*, etc.)
ECLIPSE_DIR=$(find /opt -maxdepth 1 -type d -name "eclipse*" | head -1)

if [ -z "$ECLIPSE_DIR" ]; then
    echo "ERROR: Eclipse directory not found after extraction."
    exit 1
fi

echo "$ECLIPSE_DIR" > /opt/eclipse_home

echo "Eclipse installed to: $ECLIPSE_DIR"
