import sys
import os
import subprocess

import CDocs_Module_Utils as CDocs

def main():
    if len(sys.argv) != 3:
        print("Usage: python CDocs-cdocs_include.py <input_filename> <output_filename>")
        sys.exit(1)

    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    print(" INPUT: {}".format(input_filename))
    print("OUTPUT: {}".format(output_filename))

    if not os.path.exists(input_filename):
        print("ERROR: {} doesnt exist".format(input_filename))
        sys.exit(2)

    if  os.path.exists(output_filename):
        print("ERROR: {} does exist, and it should not".format(output_filename))
        sys.exit(3)


    with open(output_filename, 'w') as f:
        f.write(f'hello')

    CONTAINER="chgray123/chgray_repro:pandoc"
    input_filename = CDocs.MapToDataDirectory(input_filename)
    output_png = input_filename +".png"





import sys
import os
import uuid
import subprocess


import CDocs_Module_Utils as CDocs
import CDocs_utils as CDocsInternal


def main():
    if len(sys.argv) != 3:
        print("Usage: python CDocs-cdocs.py <input_filename> <output_filename>")
        sys.exit(1)

    orig_input_filename = sys.argv[1]

    with open(orig_input_filename, "r") as f:
        lines = f.read()

    input_filename = orig_input_filename + ".content.html"
    with open(input_filename, "w") as f:
        f.write(lines)

    convert = "pandoc -i {} -f markdown -o {} -t html".format(input_filename, input_filename)
    os.system(convert)

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
    CDocs.RunInContainer(CONTAINER, cmd, mapped_output)

    if not os.path.exists(output_filename):
        print("ERROR: {} doesnt exist".format(output_filename))
        sys.exit(2)




if __name__ == "__main__":
    main()