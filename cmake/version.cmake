#
# Copyright (c) Marcus Holland-Moritz
#
# This file is part of dwarfs.
#
# dwarfs is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# dwarfs is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# dwarfs.  If not, see <https://www.gnu.org/licenses/>.
#

set(VERSION_SRC_FILE ${CMAKE_CURRENT_SOURCE_DIR}/src/dwarfs/version.cpp)
set(VERSION_HDR_FILE ${CMAKE_CURRENT_SOURCE_DIR}/include/dwarfs/version.h)

execute_process(
  COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" rev-parse --show-toplevel
  OUTPUT_VARIABLE GIT_TOPLEVEL_RAW
  OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

execute_process(
  COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" log --pretty=format:%h -n 1
  OUTPUT_VARIABLE PRJ_GIT_REV
  OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)

get_filename_component(GIT_TOPLEVEL "${GIT_TOPLEVEL_RAW}" REALPATH)
get_filename_component(REAL_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" REALPATH)

if((NOT "${REAL_SOURCE_DIR}" STREQUAL "${GIT_TOPLEVEL}")
   OR ("${PRJ_GIT_REV}" STREQUAL ""))
  if(NOT EXISTS ${VERSION_SRC_FILE} OR NOT EXISTS ${VERSION_HDR_FILE})
    message("REAL_SOURCE_DIR: ${REAL_SOURCE_DIR} (${CMAKE_CURRENT_SOURCE_DIR})")
    message("GIT_TOPLEVEL: ${GIT_TOPLEVEL} (${GIT_TOPLEVEL_RAW})")
    message("PRJ_GIT_REV: ${PRJ_GIT_REV}")
    message(FATAL_ERROR "missing version files")
  endif()
else()
  execute_process(
    COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" describe --tags --match "v*" --dirty
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE PRJ_GIT_DESC)
  execute_process(
    COMMAND git -C "${CMAKE_CURRENT_SOURCE_DIR}" rev-parse --abbrev-ref HEAD
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE PRJ_GIT_BRANCH)

  string(STRIP "${PRJ_GIT_REV}" PRJ_GIT_REV)
  string(STRIP "${PRJ_GIT_DESC}" PRJ_GIT_DESC)
  string(STRIP "${PRJ_GIT_BRANCH}" PRJ_GIT_BRANCH)
  string(SUBSTRING "${PRJ_GIT_DESC}" 1 -1 PRJ_VERSION_FULL)

  string(REGEX REPLACE "^v([0-9]+)\\..*" "\\1" PRJ_VERSION_MAJOR
                       "${PRJ_GIT_DESC}")
  string(REGEX REPLACE "^v[0-9]+\\.([0-9]+).*" "\\1" PRJ_VERSION_MINOR
                       "${PRJ_GIT_DESC}")
  string(REGEX REPLACE "^v[0-9]+\\.[0-9]+\\.([0-9]+).*" "\\1" PRJ_VERSION_PATCH
                       "${PRJ_GIT_DESC}")

  set(PRJ_VERSION_SHORT "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

  set(PRJ_GIT_ID ${PRJ_GIT_DESC})
  if(NOT PRJ_GIT_BRANCH STREQUAL "main")
    set(PRJ_GIT_ID "${PRJ_GIT_ID} on branch ${PRJ_GIT_BRANCH}")
  endif()

  set(PRJ_GIT_BRANCH "main")
  set(PRJ_GIT_REV "?")
  set(PRJ_GIT_DESC "?")
  set(PRJ_GIT_ID "?")

  set(VERSION_SRC
      "// autogenerated code, do not modify

#include \"dwarfs/version.h\"

namespace dwarfs {

char const* PRJ_GIT_REV = \"${PRJ_GIT_REV}\";
char const* PRJ_GIT_DESC = \"${PRJ_GIT_DESC}\";
char const* PRJ_GIT_BRANCH = \"${PRJ_GIT_BRANCH}\";
char const* PRJ_GIT_ID = \"${PRJ_GIT_ID}\";

} // namespace dwarfs")

  set(VERSION_HDR
      "// autogenerated code, do not modify

#pragma once

#define PRJ_VERSION_MAJOR ${PRJ_VERSION_MAJOR}
#define PRJ_VERSION_MINOR ${PRJ_VERSION_MINOR}
#define PRJ_VERSION_PATCH ${PRJ_VERSION_PATCH}

namespace dwarfs {

extern char const* PRJ_GIT_REV;
extern char const* PRJ_GIT_DESC;
extern char const* PRJ_GIT_BRANCH;
extern char const* PRJ_GIT_ID;

} // namespace dwarfs")

  if(EXISTS ${VERSION_SRC_FILE})
    file(READ ${VERSION_SRC_FILE} VERSION_SRC_OLD)
  else()
    set(VERSION_SRC_OLD "")
  endif()

  if(EXISTS ${VERSION_HDR_FILE})
    file(READ ${VERSION_HDR_FILE} VERSION_HDR_OLD)
  else()
    set(VERSION_HDR_OLD "")
  endif()

  if(NOT "${VERSION_SRC}" STREQUAL "${VERSION_SRC_OLD}")
    file(WRITE ${VERSION_SRC_FILE} "${VERSION_SRC}")
  endif()

  if(NOT "${VERSION_HDR}" STREQUAL "${VERSION_HDR_OLD}")
    file(WRITE ${VERSION_HDR_FILE} "${VERSION_HDR}")
  endif()
endif()
