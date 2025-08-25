#!/bin/bash

# fix-pods-config.sh - Remove CocoaPods configuration references

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Removing CocoaPods configuration references...${NC}"
echo ""

PROJECT_FILE="foris.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}❌ Project file not found: $PROJECT_FILE${NC}"
    exit 1
fi

# Create backup
echo -e "${YELLOW}📋 Creating backup...${NC}"
cp "$PROJECT_FILE" "$PROJECT_FILE.config-fix-backup"

echo -e "${YELLOW}🗑️  Removing CocoaPods configuration references...${NC}"

# Remove baseConfigurationReference lines that reference Pods
sed -i '' '/baseConfigurationReference.*Pods.*\.xcconfig/d' "$PROJECT_FILE"

# Remove the file references for Pods configuration files
sed -i '' '/5C6E1CB826B0C40C1FD0133F.*Pods-foris\.debug\.xcconfig/d' "$PROJECT_FILE"
sed -i '' '/B760650A0A0AEAF126103AFA.*Pods-foris\.release\.xcconfig/d' "$PROJECT_FILE"
sed -i '' '/A063631E18A096E969E3DDCD.*Pods-forisTests\.debug\.xcconfig/d' "$PROJECT_FILE"
sed -i '' '/187296B50313BC5FECD8E60B.*Pods-forisTests\.release\.xcconfig/d' "$PROJECT_FILE"

# Remove any remaining Pods-foris references
sed -i '' '/Pods-foris/d' "$PROJECT_FILE"
sed -i '' '/Pods-forisTests/d' "$PROJECT_FILE"

echo -e "${GREEN}✅ CocoaPods configuration references removed${NC}"

# Verify cleanup
echo -e "${YELLOW}🔍 Verifying cleanup...${NC}"
REMAINING=$(grep -c "Pods-foris\|baseConfigurationReference.*Pods" "$PROJECT_FILE" || echo "0")
echo "Remaining CocoaPods config references: $REMAINING"

if [ "$REMAINING" -eq 0 ]; then
    echo -e "${GREEN}✅ Configuration cleanup successful!${NC}"
else
    echo -e "${YELLOW}⚠️  Some references may remain${NC}"
fi

echo ""
echo -e "${GREEN}🎯 Configuration fix complete!${NC}"
echo ""
echo -e "${YELLOW}Next step: Test build${NC}"
echo "xcodebuild -project foris.xcodeproj -scheme foris -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build"
echo ""