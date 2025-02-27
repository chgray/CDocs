import os
import sys
import subprocess

def DiscoverContainerTool():
    return "podman"


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

    totalCommand = "{} run -it --rm -v {}:/data {} {}".format(DiscoverContainerTool(), PROJECT_ROOT, container, command)
    print("RUNNING CONTAINER: {}".format(totalCommand))
    subprocess.run([totalCommand], shell=True)

    if not not os.path.exists(expected_output):
        print("ERROR: {} must exist; and it doesnt".format(expected_output))
        command = "bash"
        totalCommand = "{} run -it --rm -v {}:/data {} {}".format(DiscoverContainerTool(), PROJECT_ROOT, container, command)
        print("RUNNING CONTAINER(DEBUG): {}".format(totalCommand))
        subprocess.run([totalCommand], shell=True)
        sys.exit(41)