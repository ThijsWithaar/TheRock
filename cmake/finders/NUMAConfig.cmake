include(FindPackageHandleStandardArgs)

find_path(NUMA_INCLUDE_DIRS
	NAMES numa.h
	PATHS
		/usr/local/include
		/usr/include
)

find_library(NUMA_INCLUDE_LIBRARIES
	NAMES numa
	PATHS
		/usr/local/lib
		/usr/lib
		/usr/lib/x86_64-linux-gnu
)

find_package_handle_standard_args(NUMA DEFAULT_MSG NUMA_INCLUDE_LIBRARIES)

if (NOT TARGET numa::numa)
	add_library(numa::numa UNKNOWN IMPORTED)
	set_target_properties(numa::numa PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${NUMA_INCLUDE_DIRS}")
	set_target_properties(numa::numa PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C" IMPORTED_LOCATION "${NUMA_INCLUDE_LIBRARIES}")
endif()

if(COMMAND set_package_properties)
	set_package_properties(numa PROPERTIES DESCRIPTION "numa")
endif()
