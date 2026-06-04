cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "yosintv")
set(APPLICATION_ID "net.yosintv.tv")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Include the flutter_library helper.
include(flutter/generated_plugins.cmake)

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "../flutter/generated_plugin_registrant.cc"
  ${PLUGINS_SOURCES}
)
apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_TARGET_PLATFORM_LINUX")
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE ${PLUGINS_LIBRARIES})
foreach(plugin_lib ${PLUGINS_LIBRARIES})
  set_target_properties(${plugin_lib} PROPERTIES IMPORTED_NO_SONAME 1)
endforeach()


# Generate the resource file for the bundle.
# This should be updated if your project has additional resources.
# set(RESOURCES
#   "resources/icon.png"
# )
# add_custom_command(
#   OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/resources.gresource"
#   COMMAND glib-compile-resources --target="${CMAKE_CURRENT_BINARY_DIR}/resources.gresource" --sourcedir="${CMAKE_CURRENT_SOURCE_DIR}/resources" "${CMAKE_CURRENT_SOURCE_DIR}/resources/resources.xml"
#   DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/resources/resources.xml" ${RESOURCES}
# )

# install(FILES "${CMAKE_CURRENT_BINARY_DIR}/resources.gresource" DESTINATION "${CMAKE_INSTALL_PREFIX}/data")

# Only install the executable; the assets and library will be handled by the
# Flutter tool.
install(TARGETS ${BINARY_NAME} DESTINATION "${CMAKE_INSTALL_PREFIX}" RUNTIME)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${CMAKE_INSTALL_PREFIX}/data")

install(DIRECTORY "${FLUTTER_LIBRARY_DIR}/" DESTINATION "${CMAKE_INSTALL_PREFIX}/lib"
  FILES_MATCHING PATTERN "*.so*"
)

set(CPACK_PACKAGE_NAME "${BINARY_NAME}")
set(CPACK_PACKAGE_VERSION "1.1.0")
include(CPack)
