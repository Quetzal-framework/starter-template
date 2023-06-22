include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(starter_template_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(starter_template_setup_options)
  option(starter_template_ENABLE_HARDENING "Enable hardening" ON)
  option(starter_template_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    starter_template_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    starter_template_ENABLE_HARDENING
    OFF)

  starter_template_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR starter_template_PACKAGING_MAINTAINER_MODE)
    option(starter_template_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(starter_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(starter_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(starter_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(starter_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(starter_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(starter_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(starter_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(starter_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(starter_template_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(starter_template_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(starter_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(starter_template_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(starter_template_ENABLE_IPO "Enable IPO/LTO" ON)
    option(starter_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(starter_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(starter_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(starter_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(starter_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(starter_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(starter_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(starter_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(starter_template_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(starter_template_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(starter_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(starter_template_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      starter_template_ENABLE_IPO
      starter_template_WARNINGS_AS_ERRORS
      starter_template_ENABLE_USER_LINKER
      starter_template_ENABLE_SANITIZER_ADDRESS
      starter_template_ENABLE_SANITIZER_LEAK
      starter_template_ENABLE_SANITIZER_UNDEFINED
      starter_template_ENABLE_SANITIZER_THREAD
      starter_template_ENABLE_SANITIZER_MEMORY
      starter_template_ENABLE_UNITY_BUILD
      starter_template_ENABLE_CLANG_TIDY
      starter_template_ENABLE_CPPCHECK
      starter_template_ENABLE_COVERAGE
      starter_template_ENABLE_PCH
      starter_template_ENABLE_CACHE)
  endif()

  starter_template_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (starter_template_ENABLE_SANITIZER_ADDRESS OR starter_template_ENABLE_SANITIZER_THREAD OR starter_template_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(starter_template_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(starter_template_global_options)
  if(starter_template_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    starter_template_enable_ipo()
  endif()

  starter_template_supports_sanitizers()

  if(starter_template_ENABLE_HARDENING AND starter_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR starter_template_ENABLE_SANITIZER_UNDEFINED
       OR starter_template_ENABLE_SANITIZER_ADDRESS
       OR starter_template_ENABLE_SANITIZER_THREAD
       OR starter_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${starter_template_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${starter_template_ENABLE_SANITIZER_UNDEFINED}")
    starter_template_enable_hardening(starter_template_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(starter_template_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(starter_template_warnings INTERFACE)
  add_library(starter_template_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  starter_template_set_project_warnings(
    starter_template_warnings
    ${starter_template_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(starter_template_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(starter_template_options)
  endif()

  include(cmake/Sanitizers.cmake)
  starter_template_enable_sanitizers(
    starter_template_options
    ${starter_template_ENABLE_SANITIZER_ADDRESS}
    ${starter_template_ENABLE_SANITIZER_LEAK}
    ${starter_template_ENABLE_SANITIZER_UNDEFINED}
    ${starter_template_ENABLE_SANITIZER_THREAD}
    ${starter_template_ENABLE_SANITIZER_MEMORY})

  set_target_properties(starter_template_options PROPERTIES UNITY_BUILD ${starter_template_ENABLE_UNITY_BUILD})

  if(starter_template_ENABLE_PCH)
    target_precompile_headers(
      starter_template_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(starter_template_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    starter_template_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(starter_template_ENABLE_CLANG_TIDY)
    starter_template_enable_clang_tidy(starter_template_options ${starter_template_WARNINGS_AS_ERRORS})
  endif()

  if(starter_template_ENABLE_CPPCHECK)
    starter_template_enable_cppcheck(${starter_template_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(starter_template_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    starter_template_enable_coverage(starter_template_options)
  endif()

  if(starter_template_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(starter_template_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(starter_template_ENABLE_HARDENING AND NOT starter_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR starter_template_ENABLE_SANITIZER_UNDEFINED
       OR starter_template_ENABLE_SANITIZER_ADDRESS
       OR starter_template_ENABLE_SANITIZER_THREAD
       OR starter_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    starter_template_enable_hardening(starter_template_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
