#!/bin/bash

# CocoaPods Project Cleanup Script
# This script removes all CocoaPods references from the Xcode project file

set -e

PROJECT_FILE="foris.xcodeproj/project.pbxproj"
BACKUP_FILE="foris.xcodeproj/project.pbxproj.backup"

echo "🧹 Starting CocoaPods cleanup for Xcode project..."

# Create backup
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "✅ Created backup at $BACKUP_FILE"

# Remove CocoaPods xcconfig file references
echo "🔧 Removing xcconfig file references..."
sed -i '' '/Pods-.*\.xcconfig/d' "$PROJECT_FILE"

# Remove CocoaPods framework references
echo "🔧 Removing framework references..."
sed -i '' '/Pods_.*\.framework/d' "$PROJECT_FILE"

# Remove CocoaPods build script phases
echo "🔧 Removing build script phases..."
sed -i '' '/\[CP\] Check Pods Manifest\.lock/d' "$PROJECT_FILE"
sed -i '' '/8D0F1EE068862E754E642662/d' "$PROJECT_FILE"
sed -i '' '/15D5E0F06A2156FAF3DDA929/d' "$PROJECT_FILE"

# Remove CocoaPods group references
echo "🔧 Removing Pods group..."
sed -i '' '/CC42BD76E12CD9B23D8E1A37.*Pods/d' "$PROJECT_FILE"

# Remove baseConfigurationReference lines
echo "🔧 Removing base configuration references..."
sed -i '' '/baseConfigurationReference.*Pods/d' "$PROJECT_FILE"

# Remove CocoaPods input/output paths
echo "🔧 Removing CocoaPods input/output paths..."
sed -i '' '/PODS_PODFILE_DIR_PATH/d' "$PROJECT_FILE"
sed -i '' '/PODS_ROOT/d' "$PROJECT_FILE"
sed -i '' '/Pods-.*-checkManifestLockResult\.txt/d' "$PROJECT_FILE"

# Remove CocoaPods shell script content
echo "🔧 Removing shell script content..."
sed -i '' '/diff.*Podfile\.lock.*Manifest\.lock/d' "$PROJECT_FILE"
sed -i '' '/echo.*sandbox is not in sync/d' "$PROJECT_FILE"
sed -i '' '/echo.*SUCCESS.*SCRIPT_OUTPUT_FILE/d' "$PROJECT_FILE"

echo "✅ CocoaPods references removed from project file"

# Validate the project file
if xcodebuild -list -project foris.xcodeproj > /dev/null 2>&1; then
    echo "✅ Project file validation successful"
    rm "$BACKUP_FILE"
    echo "🗑️  Removed backup file"
else
    echo "❌ Project file validation failed, restoring backup"
    mv "$BACKUP_FILE" "$PROJECT_FILE"
    exit 1
fi

echo "🎉 CocoaPods cleanup completed successfully!"