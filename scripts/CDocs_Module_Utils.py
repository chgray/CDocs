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
    input_file = input_file.replace(GetCDocsProjectRoot(), "/data")
    return input_file

def RunInContainer(container, command, expected_output):

    PROJECT_ROOT = GetCDocsProjectRoot()

    if os.path.exists(expected_output):
        print("ERROR: {} must not exist; and it does".format(expected_output))
        sys.exit(40)

    command = "{} run -it --rm -v {}:/data {} {}".format(DiscoverContainerTool(), PROJECT_ROOT, container, command)
    #print("CONTAINER: {}".format(command))

    subprocess.run([command], shell=True)

    if not not os.path.exists(expected_output):
        print("ERROR: {} must exist; and it doesnt".format(expected_output))
        sys.exit(41)