import sys
import os

import CDocs_Module_Utils as CDocs

def main():
    if len(sys.argv) != 3:
        print("Usage: python CDocs-mermaid.py <input_filename> <output_filename>")
        sys.exit(1)

    input_filename = sys.argv[1]
    output_filename = sys.argv[2]

    if not os.path.exists(input_filename):
        print("ERROR: {input_filename} doesnt exist")
        sys.exit(2)

    if  os.path.exists(output_filename):
        print("ERROR: {output_filename} does exist, and it should not")
        sys.exit(3)


    CONTAINER="chgray123/chgray_repro:cdocs.mermaid"
    input_filename = CDocs.MapToDataDirectory(input_filename)
    output_filename = CDocs.MapToDataDirectory(output_filename)

    print("CONTAINER: {} --> {} to {}".format(CONTAINER, input_filename, output_filename))
    CDocs.RunInContainer(CONTAINER, "/home/mermaidcli/node_modules/.bin/mmdc -p /puppeteer-config.json -i {} -o {} --width 1000".format(input_filename, output_filename))

if __name__ == "__main__":
    main()