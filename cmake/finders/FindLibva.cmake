find_path(FIND_LIBVA_INCLUDES
  NAMES
    va/va.h
  PATHS
    /usr/include
    /usr/local/include)

set(_libva_library_hints /usr/lib /usr/lib/x86_64-linux-gnu /usr/local/lib)

find_library(FIND_LIBVA_LIBRARIES NAMES va PATH ${_libva_library_hints})
find_library(FIND_LIBVA_DRM_LIBRARIES NAMES va-drm HINTS ${_libva_library_hints} ${ROCM_PATH}/lib/rocm_sysdeps/lib)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libva DEFAULT_MSG FIND_LIBVA_INCLUDES FIND_LIBVA_LIBRARIES FIND_LIBVA_DRM_LIBRARIES)
mark_as_advanced(FIND_LIBVA_INCLUDES FIND_LIBVA_LIBRARIES FIND_LIBVA_DRM_LIBRARIES)

#add_library(libva::libva UNKNOWN IMPORTED)
#set_target_properties(libva::libva PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${FIND_LIBVA_INCLUDES}")
#set_target_properties(libva::libva PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C" IMPORTED_LOCATION "${FIND_LIBVA_LIBRARIES}")

set(LIBVA_INCLUDE_DIR ${FIND_LIBVA_INCLUDES})
set(LIBVA_LIBRARY ${FIND_LIBVA_LIBRARIES})
set(LIBVA_DRM_LIBRARY ${FIND_LIBVA_DRM_LIBRARIES})
