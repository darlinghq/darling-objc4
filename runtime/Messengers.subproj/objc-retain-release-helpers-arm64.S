/*
 * Register-specific retain/release entry points for arm64.
 *
 * Newer compilers shorten `mov x0, xN; bl _objc_retain` to `bl _objc_retain_xN` (and likewise for
 * release). Each entry point takes the object in register xN and behaves exactly like
 * objc_retain()/objc_release() (the object is also returned in x0 for retain). x16/x17 (IP0/IP1)
 * and x18 (platform register) are not used for arguments and have no entry points.
 */

#if __arm64__

.text

.macro RETAIN_RELEASE_HELPERS
	.globl _objc_retain_x$0
	.p2align 2
_objc_retain_x$0:
	mov	x0, x$0
	b	_objc_retain

	.globl _objc_release_x$0
	.p2align 2
_objc_release_x$0:
	mov	x0, x$0
	b	_objc_release
.endmacro

RETAIN_RELEASE_HELPERS 0
RETAIN_RELEASE_HELPERS 1
RETAIN_RELEASE_HELPERS 2
RETAIN_RELEASE_HELPERS 3
RETAIN_RELEASE_HELPERS 4
RETAIN_RELEASE_HELPERS 5
RETAIN_RELEASE_HELPERS 6
RETAIN_RELEASE_HELPERS 7
RETAIN_RELEASE_HELPERS 8
RETAIN_RELEASE_HELPERS 9
RETAIN_RELEASE_HELPERS 10
RETAIN_RELEASE_HELPERS 11
RETAIN_RELEASE_HELPERS 12
RETAIN_RELEASE_HELPERS 13
RETAIN_RELEASE_HELPERS 14
RETAIN_RELEASE_HELPERS 15
RETAIN_RELEASE_HELPERS 19
RETAIN_RELEASE_HELPERS 20
RETAIN_RELEASE_HELPERS 21
RETAIN_RELEASE_HELPERS 22
RETAIN_RELEASE_HELPERS 23
RETAIN_RELEASE_HELPERS 24
RETAIN_RELEASE_HELPERS 25
RETAIN_RELEASE_HELPERS 26
RETAIN_RELEASE_HELPERS 27
RETAIN_RELEASE_HELPERS 28

#endif
