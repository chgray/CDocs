import sys
import os
import uuid
import subprocess

import CDocs_Module_Utils as CDocs

def main():
    if len(sys.argv) != 3:
        print("Usage: python CDocs-cdocs_include.py <input_filename> <output_filename>")
        sys.exit(1)

    orig_input_filename = sys.argv[1]
    input_filename = orig_input_filename+".html"
    os.rename(orig_input_filename, input_filename)
    output_filename = sys.argv[2]

    print(" XINPUT: {}".format(input_filename))
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

    #temp_output = "/tmp/{}.png".format(str(uuid.uuid4()))

    cmd = "cutycapt --url=file:///data/{} --out={} --max-wait=5000".format(mapped_input, mapped_output)
    CDocs.RunInContainer(CONTAINER, cmd, mapped_output)

    #print ("MOVING {} -> {}".format(temp_output, mapped_output))

    #with os.scandir("/tmp") as entries:
    #    for entry in entries:
    #        print(entry)

    #os.rename(temp_output, mapped_output)

    if not os.path.exists(output_filename):
        print("ERROR: {} doesnt exist".format(output_filename))
        sys.exit(2)

if __name__ == "__main__":
    main()