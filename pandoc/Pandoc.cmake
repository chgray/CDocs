set(PANDOC_DEST_DIR ${CMAKE_SOURCE_DIR}/Rendered)

function(GENERATE_PANDOC_SLIDES)
    set(library ${ARGV0})
    set(library_type ${ARGV1})
    list(REMOVE_AT ARGV 0)
    list(REMOVE_AT ARGV 0)

    message(STATUS "****** : ${PANDOC_DEST_DIR}")

    foreach(arg IN LISTS ARGV)
        get_filename_component(RAW_FILENAME ${arg} NAME)

        set(HTML_HASH_FILE ${RAW_FILENAME}.slides.html)
        set(HTML_OUTPUT_FILE ${PANDOC_DEST_DIR}/${arg}.slides.html)
        get_filename_component(OUTPUT_DIR ${HTML_OUTPUT_FILE} DIRECTORY)


        get_filename_component(OUTPUT_DIR ${HTML_OUTPUT_FILE} DIRECTORY)

        message(STATUS "OutputFile : ${HTML_OUTPUT_FILE} coming from ${arg}")
        message(STATUS "OutputDir : ${OUTPUT_DIR}")

        add_custom_command(
            OUTPUT ${HTML_HASH_FILE}
            DEPENDS ${arg}

            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}

            COMMENT "pandoc -t slidy -s ${arg} -o ${HTML_OUTPUT_FILE} --lua-filter /lua-filters/include-files.lua -F mermaid-filter --filter pandoc-plantuml"

            COMMAND mkdir -p ${OUTPUT_DIR}
            COMMAND pandoc -t slidy -s ${arg} -o ${HTML_OUTPUT_FILE} --lua-filter /lua-filters/include-files.lua -F mermaid-filter --filter pandoc-plantuml
        )

        message(STATUS ">>>>>>> Pandoc Source File = ${RAW_FILENAME} output = ${HTML_HASH_FILE}")
        list(APPEND pandoc_output_files ${HTML_HASH_FILE})
    endforeach()

    message(STATUS "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
    message(STATUS "pandoc outputs = ${pandoc_output_files}")
    add_custom_target(${library} DEPENDS ${pandoc_output_files})
endfunction()


function(GENERATE_PDFS)
    set(library ${ARGV0})
    set(library_type ${ARGV1})
    list(REMOVE_AT ARGV 0)
    list(REMOVE_AT ARGV 0)

    message(STATUS "****** : ${PANDOC_DEST_DIR}")

    foreach(arg IN LISTS ARGV)
        get_filename_component(RAW_FILENAME ${arg} NAME)

        set(HTML_HASH_FILE ${RAW_FILENAME}.docx)
        set(HTML_OUTPUT_FILE ${PANDOC_DEST_DIR}/${arg}.docx)
        get_filename_component(OUTPUT_DIR ${HTML_OUTPUT_FILE} DIRECTORY)

        message(STATUS "OutputFile : ${HTML_OUTPUT_FILE} coming from ${arg}")
        message(STATUS "OutputDir : ${OUTPUT_DIR}")

        add_custom_command(
            OUTPUT ${HTML_HASH_FILE}
            DEPENDS ${arg}

            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}

            COMMENT "pandoc -s ./${arg} -o ${HTML_OUTPUT_FILE} --lua-filter /lua-filters/include-files.lua -F mermaid-filter"

            COMMAND mkdir -p ${OUTPUT_DIR}
            COMMAND pandoc -s ./${arg} -o ${HTML_OUTPUT_FILE} --lua-filter /lua-filters/include-files.lua -F mermaid-filter
        )

        message(STATUS ">>>>>>> Pandoc Source File = ${RAW_FILENAME} output = ${HTML_HASH_FILE}")
        list(APPEND pandoc_output_files ${HTML_HASH_FILE})
    endforeach()

    message(STATUS "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
    message(STATUS "pandoc outputs = ${pandoc_output_files}")
    add_custom_target(${library} DEPENDS ${pandoc_output_files})
endfunction()
