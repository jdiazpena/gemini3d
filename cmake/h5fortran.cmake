# Leave h5fortran as FetchContent as we use wrangle HDF5 library distinctions there
if(hdf5)

  set(h5fortran_BUILD_TESTING false CACHE BOOL "h5fortran no test")

  find_package(h5fortran CONFIG QUIET)
  if(h5fortran_FOUND)
    include(${h5fortran_DIR}/h5fortranTargets.cmake)
  else()
    include(FetchContent)
    FetchContent_Declare(h5proj
      GIT_REPOSITORY ${h5fortran_url}
      GIT_TAG ${h5fortran_tag}
      GIT_SHALLOW true)

    FetchContent_MakeAvailable(h5proj)
  endif()

else(hdf5)
  message(VERBOSE " using h5fortran dummy")

  add_library(h5fortran ${CMAKE_CURRENT_SOURCE_DIR}/src/vendor/h5fortran/dummy.f90)
  target_include_directories(h5fortran INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/include)
  set_target_properties(h5fortran PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include)
  add_library(h5fortran::h5fortran ALIAS h5fortran)
endif(hdf5)
