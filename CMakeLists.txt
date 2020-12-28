cmake_minimum_required(VERSION 3.0)

project(audiounit_c)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/make_unit.app/Contents/MacOS")


add_executable(make_unit make_unit.m)
target_link_libraries(make_unit "-framework Cocoa" "-framework AudioUnit" "-framework AudioToolbox")
