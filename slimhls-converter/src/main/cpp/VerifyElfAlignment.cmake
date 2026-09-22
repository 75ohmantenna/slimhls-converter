if(NOT ANDROID_ABI STREQUAL "arm64-v8a" AND NOT ANDROID_ABI STREQUAL "x86_64")
    return()
endif()

execute_process(
    COMMAND "${READELF}" -lW "${ELF_FILE}"
    RESULT_VARIABLE READELF_RESULT
    OUTPUT_VARIABLE PROGRAM_HEADERS
    ERROR_VARIABLE READELF_ERROR
)

if(NOT READELF_RESULT EQUAL 0)
    message(FATAL_ERROR "Unable to inspect ${ELF_FILE}: ${READELF_ERROR}")
endif()

string(REGEX MATCHALL "LOAD[^\n\r]*" LOAD_SEGMENTS "${PROGRAM_HEADERS}")
if(LOAD_SEGMENTS STREQUAL "")
    message(FATAL_ERROR "No ELF load segment found in ${ELF_FILE}")
endif()

foreach(LOAD_SEGMENT IN LISTS LOAD_SEGMENTS)
    string(REGEX MATCH "0x[0-9a-fA-F]+[ \t]*$" ALIGNMENT "${LOAD_SEGMENT}")
    string(STRIP "${ALIGNMENT}" ALIGNMENT)
    if(ALIGNMENT STREQUAL "")
        message(FATAL_ERROR "Unable to read load-segment alignment: ${LOAD_SEGMENT}")
    endif()

    math(EXPR ALIGNMENT_VALUE "${ALIGNMENT}")
    math(EXPR ALIGNMENT_REMAINDER "${ALIGNMENT_VALUE} % 16384")
    if(ALIGNMENT_VALUE LESS 16384 OR NOT ALIGNMENT_REMAINDER EQUAL 0)
        message(FATAL_ERROR
            "${ANDROID_ABI} binary is not 16 KiB aligned: ${LOAD_SEGMENT}")
    endif()
endforeach()

message(STATUS "Verified 16 KiB-compatible load segments in ${ELF_FILE}")
