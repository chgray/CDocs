import os
import sys
import subprocess

def DiscoverContainerTool():
    return "docker"

def GetCDocsProjectRoot():

    current_directory = os.getcwd()

    while True:
        if '.CDocs.config' in os.listdir(current_directory):
            return current_directory

        parent_directory = os.path.dirname(current_directory)

        if parent_directory == current_directory:
            return None

        current_directory = parent_directory

def MapToDataDirectory(input_file):
    input_file =  os.path.abspath(input_file)

    print("  INOUT : {}".format(input_file))
    print("   PROJ : {}".format(GetCDocsProjectRoot()))

    input_file = "./{}".format(os.path.relpath(input_file, GetCDocsProjectRoot()))
    print(" MAPPED : {}".format(input_file))
    #input_file = input_file.replace(GetCDocsProjectRoot(), "/data")
    return input_file


#
# THE RULES:
#    Paths are complicated; mapping in and out of containers is a bear
#
#    To achieve some consistency here, there are some rules
#       1. the container launches and set the CWD to the directory that hosts .CDocs_config
#       2. if that doesnt work for you, "figure it out" :)
#
def RunInContainer(container, command, expected_output):
    PROJECT_ROOT = GetCDocsProjectRoot()

    if os.path.exists(expected_output):
        print("ERROR: {} must not exist; and it does".format(expected_output))
        sys.exit(40)

    totalCommand = "{} run --rm -v {}:/data {} {}".format(DiscoverContainerTool(), PROJECT_ROOT, container, command)
    # totalCommand = []
    # totalCommand.append(DiscoverContainerTool())
    # totalCommand.append("run")
    # #totalCommand.append("-it")
    # totalCommand.append("--rm")
    # #totalCommand.append("-v")
    # #totalCommand.append(PROJECT_ROOT + ":/data")
    # totalCommand.append(container)
    # totalCommand.append("bash")
    # totalCommand.append("-c")
    # #totalCommand.append("ps")
    # totalCommand.append(command)

    print("")
    print("PYTHON RUNNING CONTAINER:")
    print("-------------------------------------------------------------------------")
    print(totalCommand)
    print("-------------------------------------------------------------------------")
    print("")

    subprocess.run(totalCommand, shell=True)

    #import code
    #code.interact(local=locals())
    print("------")

    #raise FileNotFoundError("grrrr.")

    if not os.path.exists(expected_output):
        print("ERROR: {} must exist; and it doesnt".format(expected_output))
        raise ValueError("Output file doesnt exit")
        os._exit(456)
        #import code
        #code.interact(local=locals())

        #command = "bash"
        #totalCommand = "{} run -it --rm -v {}:/data {} {}".format(DiscoverContainerTool(), PROJECT_ROOT, container, command)
        #print("RUNNING CONTAINER(DEBUG): [{}]".format(totalCommand))
        ##result = subprocess.run(totalCommand, shell=True, capture_output=True, text=True)
        #print(result.stdout)  # Output: Hello
        #print(result.returncode)  # Output: 0)

        print("BACK")
        sys.exit(41)
    else:
        print("GOOD")
        print(f"GOOD: expected output exists {expected_output} (size: {os.path.getsize(expected_output)} bytes, full path: {os.path.abspath(expected_output)})")
        print("DONE")

    print("BYE")
