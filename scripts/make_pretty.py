#!/usr/bin/env python3
"""
make_pretty.py - Convert C# source files to formatted HTML

This script takes a C# source file and converts it to syntax-highlighted HTML
using the Pygments library for beautiful code formatting.

Usage:
    python make_pretty.py <input.cs> <output.html>

Example:
    python make_pretty.py Program.cs formatted_code.html
"""

import sys
import os
import argparse
from pathlib import Path

try:
    from pygments import highlight
    from pygments.lexers import CSharpLexer
    from pygments.formatters import HtmlFormatter
    from pygments.styles import get_style_by_name
except ImportError:
    print("Error: Pygments library is required. Install it with:")
    print("pip install pygments")
    sys.exit(1)


def format_csharp_to_html(input_file, output_file, style='default', line_numbers=True):
    """
    Convert C# source code to beautifully formatted HTML.

    Args:
        input_file (str): Path to the input C# file
        output_file (str): Path to the output HTML file
        style (str): Pygments style to use (default, monokai, github, etc.)
        line_numbers (bool): Whether to include line numbers
    """

    # Validate input file
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' does not exist.")
        return False

    # Read the C# source code
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            code = f.read()
    except Exception as e:
        print(f"Error reading input file: {e}")
        return False

    # Create the lexer for C#
    lexer = CSharpLexer()

    # Configure the HTML formatter
    formatter = HtmlFormatter(
        style=style,
        linenos=line_numbers,
        cssclass="highlight",
        full=True
    )

    # Generate the highlighted HTML
    try:
        highlighted_code = highlight(code, lexer, formatter)
    except Exception as e:
        print(f"Error formatting code: {e}")
        return False

    # Write the HTML output
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(highlighted_code)
        print(f"Successfully formatted '{input_file}' to '{output_file}'")
        print(f"Style used: {style}")
        return True
    except Exception as e:
        print(f"Error writing output file: {e}")
        return False


def list_available_styles():
    """List all available Pygments styles."""
    from pygments.styles import get_all_styles
    styles = list(get_all_styles())
    print("Available styles:")
    for style in sorted(styles):
        print(f"  - {style}")


def main():
    parser = argparse.ArgumentParser(
        description="Convert C# source files to beautifully formatted HTML",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python make_pretty.py Program.cs output.html
  python make_pretty.py --style monokai Program.cs dark_output.html
  python make_pretty.py --no-line-numbers Program.cs clean_output.html
  python make_pretty.py --list-styles
        """
    )

    parser.add_argument('input_file', nargs='?', help='Input C# source file (.cs)')
    parser.add_argument('output_file', nargs='?', help='Output HTML file')
    parser.add_argument('--style', '-s', default='default',
                        help='Pygments style to use (default: default)')
    parser.add_argument('--no-line-numbers', action='store_true',
                        help='Disable line numbers in output')
    parser.add_argument('--list-styles', action='store_true',
                        help='List all available styles and exit')

    args = parser.parse_args()

    # Handle list styles option
    if args.list_styles:
        list_available_styles()
        return

    # Validate arguments
    if not args.input_file or not args.output_file:
        parser.print_help()
        print("\nError: Both input_file and output_file are required (unless using --list-styles)")
        sys.exit(1)

    # Validate that input file has .cs extension
    if not args.input_file.lower().endswith('.cs'):
        print("Warning: Input file doesn't have .cs extension. Proceeding anyway...")

    # Validate that output file has .html extension
    if not args.output_file.lower().endswith('.html'):
        print("Warning: Output file doesn't have .html extension. Proceeding anyway...")

    # Validate style exists
    try:
        get_style_by_name(args.style)
    except Exception:
        print(f"Error: Style '{args.style}' not found.")
        print("Use --list-styles to see available styles.")
        sys.exit(1)

    # Format the file
    success = format_csharp_to_html(
        args.input_file,
        args.output_file,
        style=args.style,
        line_numbers=not args.no_line_numbers
    )

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
