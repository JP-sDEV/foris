#!/bin/bash

# build.sh - Build script for Foris iOS App
# Usage: ./Scripts/build.sh [debug|release|archive|test|clean]

set -e  # Exit on any error

# Configuration
PROJECT_NAME="foris"
SCHEME_NAME="foris"
PROJECT_FILE="foris.xcodeproj"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Xcode is installed
check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode command line tools not found. Please install Xcode."
        exit 1
    fi
    
    log_info "Xcode version: $(xcodebuild -version | head -n 1)"
}

# Clean build folder
clean_build() {
    log_info "Cleaning build folder..."
    
    xcodebuild clean -project "$PROJECT_FILE" -scheme "$SCHEME_NAME"
    
    log_success "Build folder cleaned"
}

# Install dependencies
install_dependencies() {
    log_info "Resolving Swift Package Manager dependencies..."
    
    xcodebuild -resolvePackageDependencies -project "$PROJECT_FILE" -scheme "$SCHEME_NAME"
    
    log_success "Swift Package Manager dependencies resolved"
}

# Build for debug
build_debug() {
    log_info "Building for Debug..."
    
    xcodebuild build \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -quiet
    
    log_success "Debug build completed"
}

# Build for release
build_release() {
    log_info "Building for Release..."
    
    xcodebuild build \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        -quiet
    
    log_success "Release build completed"
}

# Create archive
create_archive() {
    log_info "Creating archive..."
    
    ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
    
    # Create build directory
    mkdir -p ./build
    
    xcodebuild archive \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        -archivePath "$ARCHIVE_PATH" \
        -quiet
    
    log_success "Archive created at: $ARCHIVE_PATH"
    
    # Export IPA
    if [ -f "ExportOptions.plist" ]; then
        log_info "Exporting IPA..."
        
        xcodebuild -exportArchive \
            -archivePath "$ARCHIVE_PATH" \
            -exportPath "./build" \
            -exportOptionsPlist "ExportOptions.plist" \
            -quiet
        
        log_success "IPA exported to ./build/"
    else
        log_warning "ExportOptions.plist not found. Skipping IPA export."
    fi
}

# Run tests
run_tests() {
    log_info "Running tests..."
    
    xcodebuild test \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -quiet
    
    log_success "Tests completed"
}

# Validate archive
validate_archive() {
    ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
    
    if [ ! -d "$ARCHIVE_PATH" ]; then
        log_error "Archive not found at $ARCHIVE_PATH"
        exit 1
    fi
    
    log_info "Validating archive..."
    
    xcodebuild -validateArchive \
        -archivePath "$ARCHIVE_PATH" \
        -quiet
    
    log_success "Archive validation completed"
}

# Show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  debug     - Build for debug configuration"
    echo "  release   - Build for release configuration"
    echo "  archive   - Create archive for distribution"
    echo "  test      - Run unit and UI tests"
    echo "  validate  - Validate existing archive"
    echo "  clean     - Clean build folder and derived data"
    echo "  deps      - Install dependencies only"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 debug"
    echo "  $0 archive"
    echo "  $0 test"
}

# Main script
main() {
    log_info "Starting build process for $PROJECT_NAME"
    
    # Check prerequisites
    check_xcode
    
    case "${1:-debug}" in
        "debug")
            install_dependencies
            clean_build
            build_debug
            ;;
        "release")
            install_dependencies
            clean_build
            build_release
            ;;
        "archive")
            install_dependencies
            clean_build
            create_archive
            validate_archive
            ;;
        "test")
            install_dependencies
            run_tests
            ;;
        "validate")
            validate_archive
            ;;
        "clean")
            clean_build
            ;;
        "deps")
            install_dependencies
            ;;
        "help"|"-h"|"--help")
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
    
    log_success "Build process completed successfully!"
}

# Run main function with all arguments
main "$@"