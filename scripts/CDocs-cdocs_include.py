import sys
import os
import time
import uuid
import subprocess
import pdb
import code

import CDocs_Module_Utils as CDocs
import CDocs_utils as CDocsInternal


def CSharp_Include(file, startToken, endToken, tabLeft=True ):
    "Include..."

    print("**** - CSharp_Include({},{},{},{})".format(file, startToken, endToken, tabLeft))

    baseDir = os.getcwd()
    print("BASEDIR {}".format(baseDir))
    code = ""
    code +=  CDocsInternal.Include(baseDir, file, startToken, endToken, tabLeft)

    print("CODE: {}".format(code))
    return code


def main():

    if len(sys.argv) != 3:
        print("Usage: python CDocs-cdocs_include.py <input_filename> <output_filename>")
        sys.exit(1)

    orig_input_filename = sys.argv[1]

    if not os.path.exists(orig_input_filename):
        print(f'Input file doesnt exist {orig_input_filename}')
        sys.exit(2)

    with open(orig_input_filename, "r") as f:
        lines = f.read()

    lines = lines.replace("{{", "")
    lines = lines.replace("}}", "")
    lines = lines.replace("\n", "")
    lines = lines.strip()
    print(lines)

    execCmd = "stuff=" + lines
    print(f"EXEC: {execCmd}")

    exec(execCmd, globals())
    print("STUFF : {}".format(globals().get('stuff', 'NOT_FOUND')))

    # Ensure stuff variable exists (it should be created by exec above)
    if 'stuff' not in globals():
        print("ERROR: stuff variable was not created by exec command")
        sys.exit(2)

    input_filename = orig_input_filename + ".content.html"
    try:
        # Use make_pretty.py instead of pandoc for HTML conversion
        script_dir = os.path.dirname(os.path.abspath(__file__))
        make_pretty_script = os.path.join(script_dir, "make_pretty.py")

        # Create a temporary .cs file since make_pretty.py expects C# files
        temp_cs_filename = orig_input_filename + ".temp.cs"
        with open(temp_cs_filename, "w") as f:
            f.write(globals()['stuff'])  # stuff is created dynamically by exec() above

        try:
            convert_cmd = f"python \"{make_pretty_script}\" \"{temp_cs_filename}\" \"{input_filename}\""
            result = os.system(convert_cmd)
            if result != 0:
                print(f"ERROR: make_pretty.py failed with exit code {result}")
                sys.exit(2)
        finally:
            # Clean up temporary .cs file
            if os.path.exists(temp_cs_filename):
                os.remove(temp_cs_filename)

        output_filename = sys.argv[2]

        print(" INPUT: {}".format(input_filename))
        print("OUTPUT: {}".format(output_filename))

        if not os.path.exists(input_filename):
            print("ERROR: {} doesnt exist".format(input_filename))
            sys.exit(2)

        if  os.path.exists(output_filename):
            print("ERROR: {} does exist, and it should not".format(output_filename))
            sys.exit(3)

        mapped_input = CDocs.MapToDataDirectory(input_filename)
        print("MAPPED_INPUT: {}".format(mapped_input))

        mapped_output = os.path.abspath("/data/"+CDocs.MapToDataDirectory(output_filename))
        print("MAPPED_OUT: {}".format(mapped_output))

        CONTAINER="chgray123/chgray_repro:pandoc"
        input_filename = CDocs.MapToDataDirectory(input_filename)

        cmd = "cutycapt --url=file:///data/{} --out={} --max-wait=5000".format(mapped_input, mapped_output)
        CDocs.RunInContainer(CONTAINER, cmd, output_filename)

        if not os.path.exists(output_filename):
            print("ERROR: {} (cDocs-cdocs_include) doesnt exist".format(output_filename))
            sys.exit(2)

    finally:

        if os.path.exists(input_filename):
            os.remove(input_filename)



if __name__ == "__main__":
    main()