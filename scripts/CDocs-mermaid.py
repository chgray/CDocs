import sys
import os
import subprocess

import CDocs_Module_Utils as CDocs

def main():
    print("CDocs-mermaid.py")
    print("-------------------------------")

    if len(sys.argv) != 3:
        print("Usage: python CDocs-mermaid.py <input_filename> <output_filename>")
        sys.exit(1)

    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    if not os.path.exists(input_filename):
        print("ERROR: {} doesnt exist".format(input_filename))
        sys.exit(2)

    if  os.path.exists(output_filename):
        print("ERROR: {} does exist, and it should not".format(output_filename))
        sys.exit(3)


    CONTAINER="chgray123/chgray_repro:cdocs.mermaid"
    input_filename = CDocs.MapToDataDirectory(input_filename)
    output_filename = CDocs.MapToDataDirectory(output_filename)

    CDocs.RunInContainer(CONTAINER, "/home/mermaidcli/node_modules/.bin/mmdc -p /puppeteer-config.json -i {} -o {} --width 1000".format(input_filename, output_filename), output_filename)

    if not os.path.exists(output_filename):
        print("ERROR: {} doesnt exist".format(output_filename))
        raise ValueError("MISSING OUTPUT FILE")
        os._exit(2)
    #print("GOOD.  created {}".format(output_filename))
if __name__ == "__main__":
    main()