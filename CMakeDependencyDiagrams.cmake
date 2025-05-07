set(CMAKE_BUILD_DOCUMENTATION_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/CMakeDependencyDiagrams)
get_filename_component(CMAKE_BUILD_DOCUMENTATION_RESOURCES_DIR 
                       "${CMAKE_CURRENT_LIST_FILE}/"
                       DIRECTORY)
set(CMAKE_BUILD_DOCUMENTATION_RESOURCES_DIR ${CMAKE_BUILD_DOCUMENTATION_RESOURCES_DIR}/CMakeDependencyDiagrams)                       

configure_file(${CMAKE_BUILD_DOCUMENTATION_RESOURCES_DIR}/index.html
               ${CMAKE_BUILD_DOCUMENTATION_OUTPUT}/index.html)
configure_file(${CMAKE_BUILD_DOCUMENTATION_RESOURCES_DIR}/CMakeGraphVizOptions.cmake ${CMAKE_BINARY_DIR}/CMakeGraphVizOptions.cmake)              

add_custom_command(
  OUTPUT ${CMAKE_BUILD_DOCUMENTATION_OUTPUT}/listOfTargetFileDependencyDiagrams.js
  DEPENDS ${CMAKE_BINARY_DIR}/cmake.dot
  COMMAND ${CMAKE_BUILD_DOCUMENTATION_RESOURCES_DIR}/convert_dot_files_to_png.sh
          ${CMAKE_BINARY_DIR}/ ${CMAKE_BUILD_DOCUMENTATION_OUTPUT}
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  COMMENT "Creating build graph for configuration: ${CMAKE_BUILD_TYPE}")

add_custom_target(
  cmake-dependency-diagrams
  COMMENT "Create CMake build documentation at ${CMAKE_BUILD_DOCUMENTATION_OUTPUT}/index.html"
  DEPENDS ${CMAKE_BUILD_DOCUMENTATION_OUTPUT}/index.html ${CMAKE_BUILD_DOCUMENTATION_OUTPUT}/listOfTargetFileDependencyDiagrams.js)
