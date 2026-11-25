// Copyright (C) 2026 Lubos Dolezel
//
// Guest test: _class_setCustomDeallocInitiation(). Observed on macOS 26.7.3
// (x86_64) with the same calls: once a class has called it, the last release
// of its instances, of instances of its subclasses, and of instances made
// before the call, sends -_objc_initiateDealloc instead of -dealloc, on the
// thread that released; an earlier release does not; the method can then
// deallocate with _objc_deallocOnMainThreadHelper(), which sends -dealloc.
// NSProxy subclasses behave the same. Other classes are not affected.
#import <Foundation/Foundation.h>
#include <dispatch/dispatch.h>
#include <stdio.h>

extern void _class_setCustomDeallocInitiation(Class);
extern void _objc_deallocOnMainThreadHelper(void *);

static int initiated, deallocated;
static BOOL initiatedOnMainThread;

static int failures;

static void report(const char *name, BOOL ok)
{
    printf("%s: %s\n", ok ? "PASS" : "FAIL", name);
    if (!ok)
        failures++;
}

@interface Base : NSObject
@end

@implementation Base
- (void)_objc_initiateDealloc
{
    initiated++;
    initiatedOnMainThread = [NSThread isMainThread];
    _objc_deallocOnMainThreadHelper(self);
}

- (void)dealloc
{
    deallocated++;
    [super dealloc];
}
@end

@interface Subclass : Base
@end

@implementation Subclass
@end

@interface Plain : NSObject
@end

@implementation Plain
- (void)_objc_initiateDealloc
{
    initiated++;
    [self dealloc];
}

- (void)dealloc
{
    deallocated++;
    [super dealloc];
}
@end

@interface Proxy : NSProxy
@end

@implementation Proxy
- (void)_objc_initiateDealloc
{
    initiated++;
    _objc_deallocOnMainThreadHelper(self);
}

- (void)dealloc
{
    deallocated++;
    [super dealloc];
}
@end

static void reset(void)
{
    initiated = deallocated = 0;
}

int main(void)
{
    @autoreleasepool {
        Base *early = [Base new];
        [[Plain new] release];
        report("before the call: plain dealloc", initiated == 0 && deallocated == 1);

        _class_setCustomDeallocInitiation([Base class]);
        reset();
        [[Base new] release];
        report("instance: initiated, then deallocated", initiated == 1 && deallocated == 1);

        reset();
        [early release];
        report("instance made before the call", initiated == 1 && deallocated == 1);

        reset();
        [[Subclass new] release];
        report("subclass instance", initiated == 1 && deallocated == 1);

        reset();
        Base *twice = [Base new];
        [twice retain];
        [twice release];
        BOOL notYet = initiated == 0;
        [twice release];
        report("only the last release", notYet && initiated == 1 && deallocated == 1);

        reset();
        // __block, so that copying the block does not retain the object and
        // the release in the block is the last one.
        __block Base *background = [Base new];
        dispatch_semaphore_t done = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [background release];
            dispatch_semaphore_signal(done);
        });
        dispatch_semaphore_wait(done, DISPATCH_TIME_FOREVER);
        report("on the releasing thread", initiated == 1 && !initiatedOnMainThread && deallocated == 1);

        reset();
        [[Plain new] release];
        report("other classes unaffected", initiated == 0 && deallocated == 1);

        _class_setCustomDeallocInitiation([Proxy class]);
        reset();
        [[Proxy alloc] release];
        report("NSProxy subclass", initiated == 1 && deallocated == 1);
    }
    return failures != 0;
}
