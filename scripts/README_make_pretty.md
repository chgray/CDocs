# make_pretty.py - C# to HTML Formatter

A Python script that converts C# source files into beautifully formatted HTML with syntax highlighting.

## Features

- **Syntax highlighting** for C# code using the powerful Pygments library
- **Multiple color themes** (40+ built-in styles including monokai, github-dark, solarized, etc.)
- **Line numbers** (optional)
- **Full HTML document** output with proper CSS styling
- **Command-line interface** with helpful options

## Installation

1. Ensure you have Python 3.6+ installed
2. Install the required dependency:
   ```bash
   pip install -r requirements.txt
   ```
   Or directly:
   ```bash
   pip install pygments
   ```

## Usage

### Basic Usage
```bash
python make_pretty.py input.cs output.html
```

### With Custom Style
```bash
python make_pretty.py --style monokai Program.cs dark_output.html
```

### Without Line Numbers
```bash
python make_pretty.py --no-line-numbers Program.cs clean_output.html
```

### List Available Styles
```bash
python make_pretty.py --list-styles
```

## Available Styles

The script supports 40+ syntax highlighting styles including:
- `default` - Clean, readable default style
- `monokai` - Popular dark theme
- `github-dark` - GitHub's dark theme
- `solarized-dark` / `solarized-light` - Solarized color scheme
- `vs` - Visual Studio style
- `dracula` - Dracula theme
- `one-dark` - Atom's One Dark theme
- And many more...

## Command Line Options

- `input_file` - Path to the C# source file (.cs)
- `output_file` - Path for the output HTML file
- `--style, -s` - Specify the syntax highlighting style (default: 'default')
- `--no-line-numbers` - Disable line numbers in the output
- `--list-styles` - Show all available styles and exit
- `--help, -h` - Show help message

## Examples

1. **Basic formatting with default style:**
   ```bash
   python make_pretty.py Program.cs formatted.html
   ```

2. **Dark theme with monokai:**
   ```bash
   python make_pretty.py --style monokai MyClass.cs dark_formatted.html
   ```

3. **Clean output without line numbers:**
   ```bash
   python make_pretty.py --no-line-numbers --style github-dark Utils.cs clean.html
   ```

4. **See all available themes:**
   ```bash
   python make_pretty.py --list-styles
   ```

## Output

The script generates a complete HTML document with:
- Proper DOCTYPE and HTML structure
- Embedded CSS for syntax highlighting
- Responsive design
- Clean, professional formatting
- Optional line numbers
- Syntax highlighting for C# keywords, strings, comments, etc.

## Error Handling

The script includes comprehensive error handling for:
- Missing input files
- Invalid file paths
- Invalid style names
- Encoding issues
- File permission problems

## Integration

This script can be easily integrated into build processes, documentation systems, or used as part of larger code formatting workflows. It follows the same pattern as other CDocs scripts in this repository.
