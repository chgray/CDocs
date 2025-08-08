#!/bin/bash

# Check if InnerContainerTool parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <InnerContainerTool>"
    echo "  InnerContainerTool: docker or podman"
    exit 1
fi

InnerContainerTool="$1"

# Validate the InnerContainerTool parameter
if [ "$InnerContainerTool" != "docker" ] && [ "$InnerContainerTool" != "podman" ]; then
    echo "Error: InnerContainerTool must be either 'docker' or 'podman'"
    echo "Usage: $0 <InnerContainerTool>"
    exit 1
fi

if [ "$InnerContainerTool" == "docker" ]; then
    apt update
    apt install docker.io -y
fi

set -e

SCRIPT_PATH=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
echo "Script path: $SCRIPT_PATH"

export CDOCS_MARKDOWN_RENDER_PATH=$(realpath /cdocs)
# Check for required environment variable
if [ ! -d "${CDOCS_MARKDOWN_RENDER_PATH}" ]; then
    git clone --branch user/chgray/update_ubuntu http://github.com/chgray/CDocs ${CDOCS_MARKDOWN_RENDER_PATH}
fi

export PATH=${CDOCS_MARKDOWN_RENDER_PATH}/tools/CDocsMarkdownCommentRender/bin/Debug/net8.0:$PATH$

# Verify the path exists and contains the required binary
if [ ! -f "${CDOCS_MARKDOWN_RENDER_PATH}/tools/CDocsMarkdownCommentRender/bin/Debug/net8.0/CDocsMarkdownCommentRender" ]; then
    echo "ERROR: CDocsMarkdownCommentRender binary not found in CDOCS_MARKDOWN_RENDER_PATH: ${CDOCS_MARKDOWN_RENDER_PATH}"
    dotnet build ${CDOCS_MARKDOWN_RENDER_PATH}/tools/CDocsMarkdownCommentRender
fi
if [ ! -f "${CDOCS_MARKDOWN_RENDER_PATH}/tools/CDocsMarkdownCommentRender/bin/Debug/net8.0/CDocsMarkdownCommentRender" ]; then
    echo "ERROR: CDocsMarkdownCommentRender binary not found in CDOCS_MARKDOWN_RENDER_PATH: ${CDOCS_MARKDOWN_RENDER_PATH}"
    exit 1
fi

#
# Use the provided container tool instead of auto-detecting
#
echo "Using provided container tool: $InnerContainerTool"
container_tool="$InnerContainerTool"

set +e
${container_tool} image exists docker.io/chgray123/chgray_repro:pandoc

if [ $? -ne 0 ]; then
    set -e
    echo "Pulling pandoc image..."
    ${container_tool} image pull docker.io/chgray123/chgray_repro:pandoc
fi

set +e
${container_tool} image exists chgray123/chgray_repro:cdocs.mermaid

if [ $? -ne 0 ]; then
    set -e
    echo "Pulling cdocs.mermaid image..."
    ${container_tool} image pull docker.io/chgray123/chgray_repro:cdocs.mermaid
fi
set -e

echo "Done"
bash