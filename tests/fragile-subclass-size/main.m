// Copyright (C) 2026 Lubos Dolezel
//
// i386 (legacy runtime) fragile base class: a subclass without ivars of its
// own, compiled while the base class was smaller, must still get instances as
// large as the base class actually is. The subclass is compiled against
// BASE_V1; the library has the grown base class.
#import "base.h"
#import <objc/runtime.h>
#include <stdlib.h>
#include <string.h>

@interface Sub : FragileBase
@end
@implementation Sub
@end

int main(void)
{
	setvbuf(stdout, NULL, _IONBF, 0);
	int fail = 0;
	size_t bs = class_getInstanceSize([FragileBase class]);
	size_t ss = class_getInstanceSize([Sub class]);
	int ok = ss >= bs;
	printf("%s: Sub instance size 0x%zx >= base instance size 0x%zx\n", ok ? "PASS" : "FAIL", ss, bs);
	fail |= !ok;

	// Neighbouring allocations must survive filling a Sub.
	enum { N = 64 };
	unsigned char* guard[N];
	id objs[N];
	for (int i = 0; i < N; i++) { objs[i] = [Sub new]; guard[i] = malloc(16); memset(guard[i], 0xA5, 16); }
	for (int i = 0; i < N; i++) [objs[i] fill];
	int sumok = 1, guardok = 1;
	for (int i = 0; i < N; i++)
	{
		sumok &= [objs[i] sum] == 15;
		for (int j = 0; j < 16; j++) guardok &= guard[i][j] == 0xA5;
	}
	printf("%s: ivars of the grown base class are usable in a Sub\n", sumok ? "PASS" : "FAIL");
	printf("%s: neighbouring heap blocks are intact\n", guardok ? "PASS" : "FAIL");
	fail |= !sumok | !guardok;
	return fail;
}
