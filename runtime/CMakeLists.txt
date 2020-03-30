project(objc4)

cmake_minimum_required(VERSION 2.4.0)
enable_language(C CXX ASM)

add_compile_options(
	-Wno-unused-command-line-argument
)

if(COMMAND cmake_policy)
	cmake_policy(SET CMP0003 NEW)
	cmake_policy(SET CMP0005 NEW)
endif(COMMAND cmake_policy)

add_definitions(-D__STDC_NO_ATOMICS__)
#add_definitions(-D__ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__=1080)

# Override DEBUG CFLAGS because -O0 has been triggering strange bugs
set(CMAKE_C_FLAGS_DEBUG "-ggdb")
set(CMAKE_CXX_FLAGS_DEBUG "-ggdb")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -nostdinc -O2 -D__DARWIN_UNIX03 -fPIC -fblocks -fobjc-legacy-dispatch -fvisibility-inlines-hidden -fvisibility=hidden -fstrict-aliasing")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -nostdinc -nostdinc++ -O2 -mmacosx-version-min=10.9 -std=gnu++11 -D__DARWIN_UNIX03 -fPIC -fblocks -fobjc-legacy-dispatch \
			-fno-rtti -fno-exceptions -Wno-c++11-narrowing -fvisibility-inlines-hidden -fvisibility=hidden -Wno-invalid-offsetof -Wno-deprecated-objc-isa-usage \
			-Wno-cast-of-sel-type -Wstrict-aliasing=2 -Wstrict-overflow=4 -fstrict-aliasing")

add_definitions(-DOBJC_NO_GC)
add_definitions(-DTARGET_OS_IPHONE=0 -DOS_OBJECT_USE_OBJC=0)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(BEFORE ${CMAKE_SOURCE_DIR}/src/external/libcxx/include)
include_directories(${CMAKE_SOURCE_DIR}/src/external/libdispatch)
include_directories(${CMAKE_SOURCE_DIR}/src/external/foundation/Headers)
include_directories(${CMAKE_SOURCE_DIR}/src/external/libpthread/private)
include_directories(${CMAKE_SOURCE_DIR}/src/libmalloc/include)
include_directories(${CMAKE_SOURCE_DIR}/src/libunwind/include)
include_directories(${CMAKE_SOURCE_DIR}/src/libc/gen)
include_directories(${CMAKE_SOURCE_DIR}/src/dyld/include)
include_directories(${CMAKE_SOURCE_DIR}/src/kernel/libsyscall)
include_directories(${CMAKE_SOURCE_DIR}/src/launchd/liblaunch)
include_directories(${CMAKE_SOURCE_DIR}/src/external/libclosure)
#include_directories(${CMAKE_BINARY_DIR}/src/external/foundation/Headers)

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
	#objcrt.c # Windows only
	objc-runtime.mm
	objc-runtime-new.mm
	objc-runtime-old.mm
	objc-sel.mm
	objc-sel-old.mm
	objc-sel-set.mm
	objc-sync.mm
	objc-typeencoding.mm
	objc-weak.mm
	Object.mm
	Protocol.mm
	a1a2-blocktramps-arm.S
	a1a2-blocktramps-arm64.S
	a1a2-blocktramps-i386.S
	a1a2-blocktramps-x86_64.S
	a2a3-blocktramps-arm.S
	a2a3-blocktramps-i386.S
	a2a3-blocktramps-x86_64.S
	objc-sel-table.S
	Messengers.subproj/objc-msg-arm.S
	Messengers.subproj/objc-msg-arm64.S
	Messengers.subproj/objc-msg-i386.S
	Messengers.subproj/objc-msg-x86_64.S
)

#add_darling_object_library(objc32 ${objc_SRCS})
#set_target_properties(objc32 PROPERTIES COMPILE_FLAGS "-fobjc-runtime=macosx-fragile")

#add_darling_object_library(objc64 ${objc_SRCS})
#set_target_properties(objc64 PROPERTIES COMPILE_FLAGS "-fobjc-runtime=macosx")

set(DYLIB_INSTALL_NAME "/usr/lib/libobjc.A.dylib")
set(DYLIB_COMPAT_VERSION "1.0.0")
set(DYLIB_CURRENT_VERSION "228.0.0")
add_circular(objc FAT
	SOURCES ${objc_SRCS}
	#OBJECTS $<TARGET_OBJECTS:objc32> $<TARGET_OBJECTS:objc64>
	SIBLINGS system_c system_malloc system_dyld system_blocks unwind system_m macho platform system_kernel system_pthread compiler_rt libdispatch_shared
	DEPENDENCIES cxx
)
set_target_properties(objc PROPERTIES OUTPUT_NAME "objc.A")
InstallSymlink("libobjc.A.dylib" "${CMAKE_INSTALL_PREFIX}/libexec/darling/usr/lib/libobjc.dylib")

install(TARGETS objc DESTINATION libexec/darling/usr/lib)
