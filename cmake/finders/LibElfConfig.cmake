include(FindPackageHandleStandardArgs)

find_path(LIBELF_INCLUDE_DIR
	NAMES libelf.h
	PATHS
		/usr/local/include
		/usr/include
)

find_library(LIBELF_LIBRARIES
	NAMES elf
	PATHS
		/usr/local/lib
		/usr/lib
		/usr/lib/x86_64-linux-gnu
)

find_package_handle_standard_args(LibElf DEFAULT_MSG LIBELF_LIBRARIES)

if(NOT TARGET elf::elf)
	add_library(elf::elf UNKNOWN IMPORTED)
	set_target_properties(elf::elf PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${LIBELF_INCLUDE_DIR}")
	set_target_properties(elf::elf PROPERTIES IMPORTED_LINK_INTERFACE_LANGUAGES "C" IMPORTED_LOCATION "${LIBELF_LIBRARIES}")
endif()

if(COMMAND set_package_properties)
	set_package_properties(elf PROPERTIES DESCRIPTION "libelf")
	set_package_properties(elf PROPERTIES URL "https://sourceware.org/elfutils/")
endif()
