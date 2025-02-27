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

    #input_filename="bing.com"
    #CDocs.RunInContainer(CONTAINER, "cd /data/docs;/usr/bin/cutycapt --url=http://{} --out={} --max-wait=3000".format(input_filename, output_png), output_png)



if __name__ == "__main__":
    main()