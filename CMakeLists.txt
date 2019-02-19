#####################################################
# FILE NAME CMakeLists.txt                          #
#                                                   #
# WRITTEN BY Michael Brockus.                       #
#                                                   #
# PURPOSE contains CMake statements.                #
#                                                   #
#####################################################
cmake_minimum_required(VERSION 3.13.2.0 FATAL_ERROR)



#
#  CMake: Declare project
#
project(cmock LANGUAGES C DESCRIPTION "C Mocking framework.")



#
#  CMake: Creation of library   
#
add_library("cmock" STATIC)



#
#  CMake: Adding source to target
#
target_sources("cmock" PRIVATE "src/cmock.c")



#
#  CMake: Including directories to target
#
target_include_directories("cmock" 
    PUBLIC 
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>"
        "$<INSTALL_INTERFACE:src>"

    PRIVATE "src" "${CMAKE_SOURCE_DIR}/external/unity/src"
)


#
#  CMake: Give target an alias 
#
add_library("cmock::framework" ALIAS "cmock")



#
#  CMake: export project
#
install(TARGETS "cmock" EXPORT "cmockConfig"
    ARCHIVE DESTINATION "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_INSTALL_BINDIR}"
    
    INCLUDES DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)

install(DIRECTORY src DESTINATION src)

install(EXPORT cmockConfig DESTINATION share/cmockConfig/cmake)

# This makes the project importable from the build directory
export(TARGETS cmock FILE cmockConfig.cmake)