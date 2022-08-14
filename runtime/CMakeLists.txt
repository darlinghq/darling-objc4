project(objc4)

cmake_minimum_required(VERSION 3.10)
enable_language(C CXX ASM)

add_compile_options(
	-Wno-unused-command-line-argument
)

if(COMMAND cmake_policy)
	cmake_policy(SET CMP0003 NEW)
	cmake_policy(SET CMP0005 NEW)
endif(COMMAND cmake_policy)

add_definitions(-D__STDC_NO_ATOMICS__)

# Override DEBUG CFLAGS because -O0 has been triggering strange bugs
set(CMAKE_C_FLAGS_DEBUG "-ggdb -DOBJC_IS_DEBUG_BUILD=1")
set(CMAKE_CXX_FLAGS_DEBUG "-ggdb -DOBJC_IS_DEBUG_BUILD=1")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -nostdinc -O2 -D__DARWIN_UNIX03 -fPIC -fblocks -fobjc-legacy-dispatch -fvisibility-inlines-hidden -fstrict-aliasing -fno-delete-null-pointer-checks")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -nostdinc -nostdinc++ -O2 -std=gnu++14 -D__DARWIN_UNIX03 -fPIC -fblocks -fobjc-legacy-dispatch \
			-fno-rtti -fno-exceptions -Wno-c++11-narrowing -fvisibility-inlines-hidden -Wno-invalid-offsetof -Wno-deprecated-objc-isa-usage \
			-Wno-cast-of-sel-type -Wstrict-aliasing=2 -Wstrict-overflow=4 -fstrict-aliasing -fno-delete-null-pointer-checks")

add_definitions(-DOBJC_NO_GC -DOBJC_IS_DEBUG_BUILD=1)
add_definitions(-DTARGET_OS_IPHONE=0 -DOS_OBJECT_USE_OBJC=0 -D_LIBCPP_VISIBLE="")

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

set(objc_SRCS
	maptable.mm
	hashtable2.mm
	NSObject.mm
	objc-accessors.mm
	objc-auto.mm
	objc-block-trampolines.mm
	objc-cache.mm
	objc-cache-old.mm
	objc-class.mm
	objc-class-old.mm
	objc-errors.mm
	objc-exception.mm
	objc-file.mm
	objc-file-old.mm
	objc-initialize.mm
	objc-layout.mm
	objc-loadmethod.mm
	objc-load.mm
	objc-lockdebug.mm
	objc-opt.mm
	objc-os.mm
	objc-references.mm
	objc-runtime.mm
	objc-runtime-new.mm
	objc-runtime-old.mm
	objc-sel.mm
	objc-sel-old.mm
	objc-sel-set.mm
	objc-sync.mm
	objc-typeencoding.mm
	objc-weak.mm
	objc-zalloc.mm
	Object.mm
	Protocol.mm
	objc-blocktramps-arm.S
	objc-blocktramps-arm64.S
	objc-blocktramps-i386.S
	objc-blocktramps-x86_64.S
	objc-sel-table.S
	Messengers.subproj/objc-msg-arm.S
	Messengers.subproj/objc-msg-arm64.S
	Messengers.subproj/objc-msg-i386.S
	Messengers.subproj/objc-msg-x86_64.S
)

set(DYLIB_INSTALL_NAME "/usr/lib/libobjc.A.dylib")
set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "228.0.0")
add_circular(objc FAT
	SOURCES ${objc_SRCS}
	SIBLINGS system_c system_malloc system_dyld system_blocks unwind system_m macho platform system_kernel system_pthread compiler_rt libdispatch_shared
	DEPENDENCIES cxx cxxabi
)
target_link_options(objc PRIVATE
	-Wl,-sectalign,__DATA,__objc_data,0x1000
	"-Wl,-interposable_list,${CMAKE_CURRENT_SOURCE_DIR}/../interposable.txt"

	# not listed anywhere in Apple's project, and there's no `__mod_init_func` or `__objc_init_func` sections in the `libobjc` bundled with macOS,
	# but it's necessary for libobjc to initialize it's own C++ globals before the runtime is initialized
	# (i'm guessing they renamed the section so that the functions in it wouldn't get called twice: once by libobjc and once by dyld)
	-Wl,-rename_section,__DATA,__mod_init_func,__DATA,__objc_init_func

	"-Wl,-unexported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/../unexported_symbols"
)
set_target_properties(objc PROPERTIES OUTPUT_NAME "objc.A")
InstallSymlink("libobjc.A.dylib" "${CMAKE_INSTALL_PREFIX}/libexec/darling/usr/lib/libobjc.dylib")

set(DYLIB_INSTALL_NAME "/usr/lib/libobjc-trampolines.dylib")
set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "228.0.0")
add_darling_library(objc-trampolines
	dummy.c # necessary to trick CMake into creating a dylib using only assembly files
	objc-blocktramps-arm.S
	objc-blocktramps-i386.S
	objc-blocktramps-x86_64.S
	objc-blocktramps-arm64.S
)
target_link_libraries(objc-trampolines PRIVATE
	system
)
target_link_options(objc-trampolines PRIVATE
	-Wl,-not_for_dyld_shared_cache
)

install(TARGETS objc objc-trampolines DESTINATION libexec/darling/usr/lib)
