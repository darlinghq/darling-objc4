// Copyright (C) 2026 Lubos Dolezel
//
// Weak references to instances of a class that customizes retain/release
// (and so implements allowsWeakReference / retainWeakReference) must work:
// objc_storeWeak() and objc_loadWeakRetained() consult those methods while
// the weak table lock is held. Build for x86_64 and i386 (the legacy runtime).
#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <stdio.h>
#include <stdlib.h>

extern id objc_storeWeak(id *location, id obj);
extern id objc_storeWeakOrNil(id *location, id obj);
extern id objc_loadWeakRetained(id *location);

static int g_allows, g_retain_weak, g_failures;

#define CHECK(cond, msg) do { if (!(cond)) { printf("FAIL: %s\n", msg); g_failures++; } } while (0)

__attribute__((objc_root_class))
@interface Root {
	Class isa;
}
+ (id)alloc;
- (id)retain;
- (oneway void)release;
- (BOOL)allowsWeakReference;
- (BOOL)retainWeakReference;
@end

@implementation Root
+ (id)alloc { return class_createInstance(self, 0); }
- (id)retain { return self; }
- (oneway void)release { }
- (BOOL)allowsWeakReference { g_allows++; return YES; }
- (BOOL)retainWeakReference { g_retain_weak++; return YES; }
+ (void)initialize { }
@end

__attribute__((objc_root_class))
@interface Refuser {
	Class isa;
}
+ (id)alloc;
- (id)retain;
- (BOOL)allowsWeakReference;
@end

@implementation Refuser
+ (id)alloc { return class_createInstance(self, 0); }
- (id)retain { return self; }
- (BOOL)allowsWeakReference { return NO; }
+ (void)initialize { }
@end

int main(void)
{
	id obj = [Root alloc];
	id weak = nil;
	objc_storeWeak(&weak, obj);
	CHECK(weak == obj, "weak reference to an object with custom retain/release was not stored");
	CHECK(g_allows == 1, "allowsWeakReference was not consulted when storing");

	id loaded = objc_loadWeakRetained(&weak);
	CHECK(loaded == obj, "objc_loadWeakRetained did not return the object");
	CHECK(g_retain_weak == 1, "retainWeakReference was not consulted when loading");
	objc_storeWeak(&weak, nil);

	id refused = nil;
	id other = [Refuser alloc];
	CHECK(objc_storeWeakOrNil(&refused, other) == nil && refused == nil,
		"allowsWeakReference returning NO did not refuse the weak reference");

	if (g_failures == 0)
		printf("PASS\n");
	return g_failures != 0;
}
