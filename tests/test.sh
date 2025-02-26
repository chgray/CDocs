#!/bin/bash

export CDOCS_DB=./orig_docs
export CDOCS_FILTER=1

export PATH=$PATH:../tools/CDocsMarkdownCommentRender/bin/Debug/net8.0

pandoc -i ./mermaid.md -o mermaid.docx --filter CDocsMarkdownCommentRender
