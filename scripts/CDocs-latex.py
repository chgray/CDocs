import sys
import os
import subprocess
import uuid

import CDocs_Module_Utils as CDocs

def main():
    print("CDocs-latex.py")
    print("-------------------------------")

    if len(sys.argv) != 3:
        print("Usage: python CDocs-latex.py <input_filename> <output_filename>")
        sys.exit(1)

    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    print(f"")
    print(f"CDocs-Latex.py")
    print(f"-------------------------------------------")
    print(f"INPUT: {input_filename}")
    print(f"OUTPUT: {output_filename}")
    print(f"")

    if not os.path.exists(input_filename):
        print("ERROR: {} doesnt exist".format(input_filename))
        sys.exit(2)

    if  os.path.exists(output_filename):
        print("ERROR: {} does exist, and it should not".format(output_filename))
        sys.exit(3)


    #
    # GhostScript has a security issue, it wont impact us (we're in a container)
    #    so disable the check
    #
    subprocess.run([
        'sed', '-i', '/disable ghostscript format types/,+6d', '/etc/ImageMagick-6/policy.xml'
    ], capture_output=True, text=True, check=True)


    print(f"Processing LaTeX file: {input_filename}")

    # Generate temp PDF filename by replacing input extension with .pdf
    temp_pdf_filename = os.path.splitext(input_filename)[0] + ".pdf"

    # pdflatex command with output directory specified
    result = subprocess.run([
        'pdflatex',
        f'--output-directory={os.path.dirname(temp_pdf_filename)}',
        '--halt-on-error',
        input_filename
    ], capture_output=True, text=True, check=True)

    print("pdflatex completed successfully")
    print("STDOUT:", result.stdout)

    # Check if the temporary PDF was created
    if not os.path.exists(temp_pdf_filename):
        print(f"ERROR: Temporary PDF {temp_pdf_filename} was not created")
        sys.exit(6)


    result = subprocess.run([
        'convert', '-density', '300', temp_pdf_filename, '-quality', '90', output_filename
    ], capture_output=True, text=True, check=True)

    #CONTAINER="chgray123/chgray_repro:cdocs.mermaid"
    #mapped_input_filename = CDocs.MapToDataDirectory(input_filename)
    #mapped_output_filename = CDocs.MapToDataDirectory(output_filename)


    if not os.path.exists(output_filename):
        print("ERROR: FINAL OUTPUT {} doesnt exist".format(output_filename))
        raise ValueError("MISSING OUTPUT FILE")
        sys.exit(2)
    print("SUCCESS: Created {}".format(output_filename))


if __name__ == "__main__":
    main()