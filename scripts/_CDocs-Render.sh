#!/bin/bash

#
# CDocs Render Script
# ===================
#
# A wrapper script for rendering Markdown files using pandoc with the CDocs filter.
# This script simplifies the process of converting Markdown documents to various output formats.
#
# Author: CDocs Project
# Version: 1.0
#



# Script configuration
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CDOCS_FILTER="CDocsMarkdownCommentRender"

# Default settings
VERBOSE=false
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Display help information
show_help() {
    cat << EOF
${SCRIPT_NAME} - CDocs Markdown Renderer

SYNOPSIS
    ${SCRIPT_NAME} [OPTIONS] INPUT_FILE

DESCRIPTION
    A wrapper script for rendering Markdown files using pandoc with the CDocs filter.
    Converts Markdown documents to various output formats with CDocs-specific processing.

ARGUMENTS
    INPUT_FILE          The input Markdown file to process (required)

OPTIONS
    -o, --output FILE   Output file name (required)
    -r, --reverse       Enable reverse rendering mode (DOCX to Markdown)
    -v, --verbose       Enable verbose output
    -n, --dry-run       Show commands without executing them
    -h, --help          Show this help message

EXAMPLES
    # Convert markdown to DOCX
    ${SCRIPT_NAME} -o document.docx document.md

    # Reverse convert DOCX to Markdown
    ${SCRIPT_NAME} -r -o document.md document.docx

    # Verbose mode
    ${SCRIPT_NAME} -v -o report.docx document.md

ENVIRONMENT VARIABLES
    CDOCS_FILTER        Set to 1 to enable filter mode (automatically set)
    CDOCS_REVERSE       Set to 1 for reverse rendering (set by -r option)

EXIT CODES
    0    Success
    1    General error
    2    Invalid arguments
    3    Input file not found
    4    Pandoc execution failed

EOF
}

# Validate input file
validate_input_file() {
    local input_file="$1"

    if [[ -z "$input_file" ]]; then
        print_error "No input file specified"
        return 1
    fi

    if [[ ! -f "$input_file" ]]; then
        print_error "Input file not found: $input_file"
        return 1
    fi

    if [[ ! -r "$input_file" ]]; then
        print_error "Input file is not readable: $input_file"
        return 1
    fi

    return 0
}

# Execute pandoc command
execute_pandoc() {
    local input_file="$1"
    local output_file="$2"
    local reverse_mode="$3"
    local cdocs_filter="$4"
    local extract_media="$5"
    export PATH=$PATH:/cdocs/tools/CDocsMarkdownCommentRender/bin/Debug/net8.0:$PATH$
    source /mkdocs_python/bin/activate

    dotnet build /cdocs/tools/CDocsMarkdownCommentRender

    # Set environment variables
    export CDOCS_FILTER=1
    if [[ "$reverse_mode" == "true" ]]; then
        echo "REVERSE MODE ON"
        export CDOCS_REVERSE=1
    fi

    # Build pandoc command
    local pandoc_cmd="pandoc -i \"$input_file\" -o \"$output_file\""

    if [[ "$cdocs_filter" == "true" ]]; then
        echo "Filter on"
        pandoc_cmd="$pandoc_cmd --filter CDocsMarkdownCommentRender"
    fi

    if [[ "$extract_media" == "true" ]]; then
        pandoc_cmd="$pandoc_cmd --extract-media ."
    fi



    # Execute the command
    if eval "$pandoc_cmd"; then
        print_success "Successfully rendered: $output_file"
        return 0
    else
        print_error "Pandoc execution failed."
        print_error "    $pandoc_cmd"
        return 1
    fi
}

# Main function
main() {
    local input_file=""
    local output_file=""
    local reverse_mode=false

    cd /data

    # Source CDocs environment file if present
    if [[ -f "/CDocs.env" ]]; then
        print_info "Sourcing CDocs environment file: /CDocs.env"
        source /CDocs.env
    fi

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            -r|--reverse)
                reverse_mode=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                print_info "Use -h or --help for usage information"
                exit 2
                ;;
            *)
                if [[ -z "$input_file" ]]; then
                    input_file="$1"
                else
                    print_error "Multiple input files specified. Only one file is supported."
                    exit 2
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$input_file" ]]; then
        print_error "No input file specified"
        print_info "Use -h or --help for usage information"
        exit 2
    fi

    # Validate input file
    if ! validate_input_file "$input_file"; then
        exit 3
    fi

    # Validate required arguments
    if [[ -z "$output_file" ]]; then
        print_error "No output file specified"
        print_info "Use -o or --output to specify the output file"
        print_info "Use -h or --help for usage information"
        exit 2
    fi

    # Show configuration in verbose mode
    if [[ "$VERBOSE" == "true" ]]; then
        print_info "Configuration:"
        print_info "  Input file: $input_file"
        print_info "  Output file: $output_file"
        print_info "  Reverse mode: $reverse_mode"
        print_info "  Filter: $CDOCS_FILTER"
    fi

     if [[ "$reverse_mode" == "true" ]]; then
        echo "Reverse"
        if ! execute_pandoc "$input_file" "$output_file".json "false" "false" "true"; then
            exit 4
        fi

        if ! execute_pandoc "$output_file".json "$output_file" "true" "true" "false"; then
            exit 4
        fi
    else
        echo "Not Reverse"
        if ! execute_pandoc "$input_file" "$output_file" "false" "true" "true"; then
            exit 4
        fi
    fi

    print_success "Rendering completed successfully!"
}

# Error handling
set -e
trap 'print_error "Script failed on line $LINENO"' ERR

# Run main function with all arguments
main "$@"
