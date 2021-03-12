cmake_minimum_required(VERSION 3.10)

project(CDocs)

set(PANDOC_DEST_DIR "OUTPUT_DIR")

include("./pandoc/Pandoc.cmake")

add_subdirectory(Samples/DockerCICD)