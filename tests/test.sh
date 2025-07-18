#!/bin/bash

#
# CDocs Test Suite
# ================
#
# This test suite validates the CDocs Markdown Comment Render filter functionality.
# It tests both forward conversion (Markdown -> DOCX) and reverse conversion (DOCX -> Markdown).
#
# Test Plan:
# 1. Build the CDocsMarkdownCommentRender tool
# 2. Test mermaid diagram processing (MD -> DOCX -> MD)
# 3. Test include file processing (MD -> DOCX -> DOCX)
#
# Expected outcomes:
# - All pandoc conversions should complete successfully
# - Generated files should be created without errors
#

# Exit immediately on any command failure
set -e

# Enable pipefail to catch failures in pipes
set -o pipefail

# Print commands as they are executed (for debugging)
set -x

# Test configuration
export CDOCS_FILTER=1
export PATH=$PATH:../tools/CDocsMarkdownCommentRender/bin/Debug/net8.0

# Test counters
TESTS_RUN=0
TESTS_PASSED=0

# TAP (Test Anything Protocol) format output
echo "TAP version 13"

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo "# Running test: $test_name"

    if eval "$test_command"; then
        echo "ok $TESTS_RUN - $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "not ok $TESTS_RUN - $test_name"
        echo "# Test failed: $test_name"
        exit 1
    fi
}

# Helper function to check if file exists and is not empty
check_output_file() {
    local file="$1"
    local test_name="$2"

    if [[ ! -f "$file" ]]; then
        echo "not ok $TESTS_RUN - $test_name: Output file '$file' was not created"
        exit 1
    fi

    if [[ ! -s "$file" ]]; then
        echo "not ok $TESTS_RUN - $test_name: Output file '$file' is empty"
        exit 1
    fi
}

echo "1..5"  # Plan: we expect to run 5 tests

# Test 1: Build the CDocsMarkdownCommentRender tool
run_test "Build CDocsMarkdownCommentRender tool" \
    "dotnet build ../tools/CDocsMarkdownCommentRender"

# Test 2: Convert mermaid.md to DOCX
run_test "Convert mermaid.md to mermaid.docx" \
    "pandoc -i ./mermaid.md -o mermaid.docx --filter CDocsMarkdownCommentRender"

check_output_file "mermaid.docx" "mermaid.md to DOCX conversion"

# Test 3: Convert include.md to DOCX
run_test "Convert include.md to include.docx" \
    "pandoc -i ./include.md -o include.docx --filter CDocsMarkdownCommentRender"

check_output_file "include.docx" "include.md to DOCX conversion"

# Test 4: Reverse convert mermaid.docx back to Markdown
run_test "Reverse convert mermaid.docx to mermaid.compare.md" \
    "CDOCS_REVERSE=1 pandoc -i ./mermaid.docx -o mermaid.compare.md --extract-media . --filter CDocsMarkdownCommentRender"

check_output_file "mermaid.compare.md" "mermaid DOCX to Markdown conversion"

# Test 5: Reverse convert include.docx back to DOCX (round-trip test)
run_test "Reverse convert include.docx to include.compare.docx" \
    "CDOCS_REVERSE=1 pandoc -i ./include.docx -o include.compare.docx --extract-media . --filter CDocsMarkdownCommentRender"

check_output_file "include.compare.docx" "include DOCX round-trip conversion"

# Summary
echo "# Test Summary: $TESTS_PASSED/$TESTS_RUN tests passed"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo "# All tests passed successfully!"
    exit 0
else
    echo "# Some tests failed!"
    exit 1
fi
