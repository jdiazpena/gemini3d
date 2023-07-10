include(CheckFortranCompilerFlag)

# check C++ and Fortran compiler ABI compatibility

if(NOT abi_ok)
  message(CHECK_START "checking that compilers can link together")
  try_compile(abi_ok
  ${CMAKE_CURRENT_BINARY_DIR}/abi_check ${CMAKE_CURRENT_LIST_DIR}/abi_check
  abi_check
  )
  if(abi_ok)
    message(CHECK_PASS "OK")
  else()
    message(FATAL_ERROR "ABI-incompatible compilers:
    C compiler ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}
    C++ compiler ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}
    Fortran compiler ${CMAKE_Fortran_COMPILER_ID} ${CMAKE_Fortran_COMPILER_VERSION}"
    )
  endif()
endif()

# avoid MacOS unwind warnings
if(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  add_link_options(-Wl,-no_compact_unwind)
endif()

if(CMAKE_Fortran_COMPILER_ID MATCHES "^Intel")
  include(${CMAKE_CURRENT_LIST_DIR}/intel.cmake)
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  include(${CMAKE_CURRENT_LIST_DIR}/gnu.cmake)
endif()
