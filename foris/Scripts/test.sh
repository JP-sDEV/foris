#!/bin/bash

# test.sh - Test script for Foris iOS App
# Usage: ./Scripts/test.sh [unit|ui|all|coverage]

set -e  # Exit on any error

# Configuration
PROJECT_NAME="foris"
SCHEME_NAME="foris"
PROJECT_FILE="foris.xcodeproj"

# Test destinations
IPHONE_DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'

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

# List available simulators
list_simulators() {
    log_info "Available iOS Simulators:"
    xcrun simctl list devices iOS | grep -E "iPhone|iPad" | grep -v "unavailable"
}

# Boot simulator if needed
boot_simulator() {
    local device_name="$1"
    
    log_info "Checking simulator: $device_name"
    
    # Get device UDID
    local device_udid=$(xcrun simctl list devices | grep "$device_name" | grep -v "unavailable" | head -n 1 | grep -o '[A-F0-9-]\{36\}')
    
    if [ -z "$device_udid" ]; then
        log_warning "Simulator '$device_name' not found"
        return 1
    fi
    
    # Check if simulator is already booted
    local device_state=$(xcrun simctl list devices | grep "$device_udid" | grep -o 'Booted\|Shutdown')
    
    if [ "$device_state" != "Booted" ]; then
        log_info "Booting simulator: $device_name"
        xcrun simctl boot "$device_udid"
        sleep 3  # Wait for simulator to boot
    fi
    
    log_success "Simulator ready: $device_name"
}

# Run unit tests
run_unit_tests() {
    log_info "Running unit tests..."
    
    # Boot iPhone simulator
    boot_simulator "iPhone 16 Pro"
    
    xcodebuild test \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -destination "$IPHONE_DESTINATION" \
        -only-testing:"${PROJECT_NAME}Tests" | xcpretty --test --color
    
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        log_success "Unit tests passed"
    else
        log_error "Unit tests failed"
        exit $exit_code
    fi
}



# Run all tests
run_all_tests() {
    log_info "Running all tests..."
    
    # Boot iPhone simulator
    boot_simulator "iPhone 16 Pro"
    
    xcodebuild test \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -destination "$IPHONE_DESTINATION" | xcpretty --test --color
    
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        log_success "All tests passed"
    else
        log_error "Some tests failed"
        exit $exit_code
    fi
}

# Run tests with code coverage
run_coverage_tests() {
    log_info "Running tests with code coverage..."
    
    # Boot iPhone simulator
    boot_simulator "iPhone 16 Pro"
    
    xcodebuild test \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -destination "$IPHONE_DESTINATION" \
        -enableCodeCoverage YES | xcpretty --test --color
    
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        log_success "Tests with coverage completed"
        generate_coverage_report
    else
        log_error "Tests with coverage failed"
        exit $exit_code
    fi
}

# Generate coverage report
generate_coverage_report() {
    log_info "Generating coverage report..."
    
    # Find the latest test result bundle
    local derived_data_path="$HOME/Library/Developer/Xcode/DerivedData"
    local test_result_bundle=$(find "$derived_data_path" -name "*.xcresult" -type d | head -n 1)
    
    if [ -z "$test_result_bundle" ]; then
        log_warning "No test result bundle found"
        return 1
    fi
    
    log_info "Using test result bundle: $test_result_bundle"
    
    # Create coverage directory
    mkdir -p ./coverage
    
    # Export coverage data
    xcrun xccov view --report --json "$test_result_bundle" > ./coverage/coverage.json
    
    # Generate human-readable report
    xcrun xccov view --report "$test_result_bundle" > ./coverage/coverage.txt
    
    log_success "Coverage report generated in ./coverage/"
    
    # Show coverage summary
    log_info "Coverage Summary:"
    xcrun xccov view --report "$test_result_bundle" | head -n 20
}



# Clean test data
clean_test_data() {
    log_info "Cleaning test data..."
    
    # Reset simulator
    xcrun simctl shutdown all
    xcrun simctl erase all
    
    # Clean derived data
    rm -rf ~/Library/Developer/Xcode/DerivedData
    
    # Clean coverage reports
    rm -rf ./coverage
    
    log_success "Test data cleaned"
}

# Install xcpretty for better output formatting
install_xcpretty() {
    if ! command -v xcpretty &> /dev/null; then
        log_info "Installing xcpretty for better test output..."
        gem install xcpretty
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  unit         - Run unit tests only"
    echo "  all          - Run all tests (default)"
    echo "  coverage     - Run tests with code coverage"
    echo "  clean        - Clean test data and simulators"
    echo "  simulators   - List available simulators"
    echo "  help         - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 unit"
    echo "  $0 coverage"
    echo "  $0 all"
}

# Main script
main() {
    log_info "Starting test process for $PROJECT_NAME"
    
    # Check prerequisites
    check_xcode
    install_xcpretty
    
    case "${1:-all}" in
        "unit")
            run_unit_tests
            ;;
        "all")
            run_all_tests
            ;;
        "coverage")
            run_coverage_tests
            ;;
        "clean")
            clean_test_data
            ;;
        "simulators")
            list_simulators
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
    
    log_success "Test process completed successfully!"
}

# Run main function with all arguments
main "$@"