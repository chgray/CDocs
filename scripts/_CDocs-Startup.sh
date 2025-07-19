#!/bin/bash
set -e

SCRIPT_PATH=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
echo "Script path: $SCRIPT_PATH"

export CDOCS_MARKDOWN_RENDER_PATH=$(realpath /cdocs)
# Check for required environment variable
if [ ! -d "${CDOCS_MARKDOWN_RENDER_PATH}" ]; then
    git clone --branch user/chgray/update_ubuntu http://github.com/chgray/CDocs ${CDOCS_MARKDOWN_RENDER_PATH}
fi

export PATH=${CDOCS_MARKDOWN_RENDER_PATH}/tools/CDocsMarkdownCommentRender/bin/Debug/net8.0:$PATH$
export | grep CDOCS
export | grep DT

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
# See if the pandoc image exists; if not, pull it
#
echo "Determining if we're using docker or podman, docker preferred"
if command -v docker &> /dev/null; then
    echo "Using Docker."
    container_tool="docker"
elif command -v podman &> /dev/null; then
    echo "Using podman"
    container_tool="podman"
else
    echo "Either docker or podman are required"
    exit 1
fi

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

