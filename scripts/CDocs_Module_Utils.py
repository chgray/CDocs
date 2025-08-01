import os
import sys
import subprocess

def DiscoverContainerTool():
    project_root = os.environ.get("CDOCS_PROJECT_INNER_CONTAINER_TOOL")
    if project_root is None:
        return "podman"
    return "docker"

def GetCDocsProjectRoot_HostSide():
    project_root = os.environ.get("CDOCS_PROJECT_ROOT")
    if project_root is None:
        return GetCDocsProjectRoot()
    return project_root


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
    PROJECT_ROOT = GetCDocsProjectRoot_HostSide()

    if os.path.exists(expected_output):
        print("ERROR: {} must not exist; and it does".format(expected_output))
        sys.exit(40)

    # Check if CDOCS_DATA_MOUNT_MAP environment variable exists, otherwise use default
    data_mount_map = os.environ.get("CDOCS_DATA_MOUNT_MAP")
    if data_mount_map is not None:
        data_map = data_mount_map
    else:
        data_map = "{}:/data".format(PROJECT_ROOT)

    totalCommand = "{} run --rm -v {} {} {}".format(DiscoverContainerTool(), data_map, container, command)

    subprocess.run(totalCommand, shell=True)

    print("------")

    if not os.path.exists(expected_output):
        print("ERROR: {} must exist; and it doesnt".format(expected_output))
        raise ValueError("Output file doesnt exit")
    else:
        print("GOOD")
        print(f"GOOD: expected output exists {expected_output} (size: {os.path.getsize(expected_output)} bytes, full path: {os.path.abspath(expected_output)})")
        print("DONE")

    print("BYE")
