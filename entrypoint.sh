#!/bin/bash
set -euo pipefail

# --------------------------------------------------------------------
# Inputs
# These environment variables are supplied by GitHub Actions "with:"
# --------------------------------------------------------------------

PROJECT_ROOT="${INPUT_PROJECT_ROOT}"
SOURCE_LEVEL="${INPUT_SOURCE_LEVEL}"
EXTRA_CLASSPATH="${INPUT_EXTRA_CLASSPATH}"
CLEANUP_OPTIONS_JSON="${INPUT_CLEANUP_OPTIONS_JSON}"

# --------------------------------------------------------------------
# Extract Eclipse release tag from the plugin JAR
# refactoring-cli-plugin.jar includes the Maven pom metadata
# --------------------------------------------------------------------

echo "Extracting Eclipse release tag from embedded plugin POM..."

TMP_DIR="/tmp/refactoring-cli-pom"
mkdir -p "$TMP_DIR"

jar xf /opt/refactoring-cli-plugin.jar \
  META-INF/maven/io.github.nbauma109/refactoring-cli/pom.xml

POM="$TMP_DIR/META-INF/maven/io.github.nbauma109/refactoring-cli/pom.xml"

# Move extracted file to our tmp directory
if [ -f "META-INF/maven/io.github.nbauma109/refactoring-cli/pom.xml" ]; then
    mv META-INF/maven/io.github.nbauma109/refactoring-cli "$TMP_DIR/META-INF/maven/io.github.nbauma109/"
    rm -rf META-INF
fi

if [ ! -f "$POM" ]; then
    echo "FATAL: pom.xml not found inside plugin JAR!"
    exit 1
fi

ECLIPSE_REPO_URL=$(grep -oPm1 "(?<=<eclipse.release.repo>)[^<]+" "$POM")
echo "Found eclipse.release.repo: $ECLIPSE_REPO_URL"

# Extract release version (example: https://download.eclipse.org/releases/2025-09 → 2025-09)
ECLIPSE_VERSION="${ECLIPSE_REPO_URL##*/}"

echo "Resolved Eclipse version: $ECLIPSE_VERSION"

rm -rf "$TMP_DIR"

# --------------------------------------------------------------------
# Download Eclipse distribution (via helper script)
# --------------------------------------------------------------------

echo "Downloading Eclipse $ECLIPSE_VERSION..."
eclipse-download "$ECLIPSE_VERSION" "java"

ECLIPSE_HOME=$(cat /opt/eclipse_home)

echo "Eclipse installed at: $ECLIPSE_HOME"

# --------------------------------------------------------------------
# Install plugin JAR into dropins
# --------------------------------------------------------------------

echo "Installing plugin JAR into dropins..."
mkdir -p "$ECLIPSE_HOME/dropins/refactoring-cli"
cp /opt/refactoring-cli-plugin.jar "$ECLIPSE_HOME/dropins/refactoring-cli/"

# --------------------------------------------------------------------
# Run cleanup application
# --------------------------------------------------------------------

echo "Running refactoring cleanup..."

"$ECLIPSE_HOME/eclipse" \
  -nosplash \
  -application io.github.nbauma109.refactoring.cli.app \
  --source "$SOURCE_LEVEL" \
  --classpath "$EXTRA_CLASSPATH" \
  --cleanup-options "$CLEANUP_OPTIONS_JSON" \
  "$PROJECT_ROOT"

echo "Cleanup execution finished."
