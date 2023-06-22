cmake_minimum_required(VERSION 3.12)

project(quetzal-starter LANGUAGES CXX)

find_package(Boost 1.61 REQUIRED COMPONENTS program_options serialization)

find_package(SQLite3 REQUIRED)
if (SQLite3_FOUND)
    include_directories(${SQLite3_INCLUDE_DIRS})
endif()

find_package(GDAL REQUIRED)
if (GDAL_FOUND)
    include_directories(${GDAL_INCLUDE_DIR})
endif()

find_package(QUETZAL REQUIRED)
if (QUETZAL)
    include_directories(${QUETZAL_INCLUDE_DIR})
endif()

add_subdirectory(src)