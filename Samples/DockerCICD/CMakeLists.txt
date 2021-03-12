project(CICDTutorial)

set(SLIDES
    UsingCDocContainer.md
)

GENERATE_PANDOC_SLIDES(CICD_GENERATED STATIC ${SLIDES})
add_custom_target(CICDTutorial ALL DEPENDS CICD_GENERATED)