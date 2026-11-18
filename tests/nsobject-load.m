// Copyright (C) 2026 Lubos Dolezel
// NSObject declares +load (NSObject.h), so every class answers it and "[super load]" is valid in any +load
// implementation, including one in a category on an AppKit class. Expected results observed on macOS 26.7.3 and 10.14.4.
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#include <stdio.h>

static int failures;
static int baseLoads, categoryLoads, subclassLoads;

#define CHECK(cond)                                                  \
	do {                                                             \
		if (!(cond)) {                                               \
			printf("FAIL line %d: %s\n", __LINE__, #cond);           \
			failures++;                                              \
		}                                                            \
	} while (0)

@interface LoadBase : NSObject
@end
@implementation LoadBase
+ (void) load { [super load]; baseLoads++; }
@end

@interface LoadSub : LoadBase
@end
@implementation LoadSub
+ (void) load { [super load]; subclassLoads++; }
@end

// A category on an AppKit class whose +load forwards to super, as a method-swizzling category commonly does.
@interface NSApplication (PosixLoadTest)
@end
@implementation NSApplication (PosixLoadTest)
+ (void) load { [super load]; categoryLoads++; }
@end

int main(void)
{
	@autoreleasepool {
		SEL load = @selector(load);
		CHECK(class_respondsToSelector(object_getClass([NSObject class]), load));
		CHECK([NSObject respondsToSelector:load]);
		CHECK([NSResponder respondsToSelector:load]);
		CHECK([NSApplication respondsToSelector:load]);
		CHECK([NSString respondsToSelector:load]);
		// Explicit sends are valid and do nothing observable.
		@try {
			[NSObject load];
			[NSResponder load];
		} @catch (NSException* e) {
			printf("FAIL explicit +load raised: %s\n", [[e reason] UTF8String]);
			failures++;
		}
		CHECK(baseLoads == 2); // its own, plus the one the subclass forwards to
		CHECK(subclassLoads == 1);
		CHECK(categoryLoads == 1);
	}
	if (failures) {
		printf("%d failure(s)\n", failures);
		return 1;
	}
	printf("PASS\n");
	return 0;
}
