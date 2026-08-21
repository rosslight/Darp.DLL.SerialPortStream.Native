cmake_minimum_required(VERSION 3.20)

project(DarpSerialPortStreamNative LANGUAGES C CXX)

set(SERIALPORTSTREAM_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/SerialPortStream"
    CACHE PATH
    "Path to the RJCP.DLL.SerialPortStream submodule")

if(NOT EXISTS "${SERIALPORTSTREAM_ROOT}/dll/serialunix/CMakeLists.txt")
  message(FATAL_ERROR
    "RJCP.DLL.SerialPortStream is missing. Run: git submodule update --init --recursive")
endif()

add_subdirectory(
  "${SERIALPORTSTREAM_ROOT}/dll/serialunix"
  "${CMAKE_CURRENT_BINARY_DIR}/serialportstream")
