import os
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

def RunInContainer(container, command):
    print("CONTAINER: {} {}".format(container, command))
    PROJECT_ROOT = GetCDocsProjectRoot()
    command = "{} run -it --rm -v{}:/data {} {}".format(DiscoverContainerTool(), PROJECT_ROOT, container, command)
    subprocess.run([command], shell=True)