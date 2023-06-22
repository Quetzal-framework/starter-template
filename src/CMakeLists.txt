  # create an alias 
  set(${exe_name} "main")
  set(${src_name} "main.cpp")

  # Add compile target
  add_executable(${exe_name} ${src_name})

  # Require the standard
  target_compile_features(${exe_name} PRIVATE cxx_std_20)

  # Link to targets and dependencies
  target_link_libraries(${exe_name} quetzal::quetzal boost::boost GDAL::GDAL range-v3::range-v3)

  # Specifies include directories to use when compiling the target
  target_include_directories(
    ${exe_name} PRIVATE
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>)