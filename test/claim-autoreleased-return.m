/*
 * Copyright (C) 2026 Lubos Dolezel
 */
// TEST_CONFIG MEM=mrc

// objc_claimAutoreleasedReturnValue accepts a value returned through a +0
// autoreleasing convention for use at +1: the caller ends up owning one
// reference, whether or not the return was optimized.

#include "test.h"
#include "testroot.i"
#include <objc/objc-internal.h>

OBJC_EXPORT id _Nullable
objc_claimAutoreleasedReturnValue(id _Nullable obj);

@interface TestObject : TestRoot @end
@implementation TestObject @end

int main()
{
    // Unoptimized path: no pending optimized return, so the value is retained.
    id obj = [[TestObject alloc] init];
    testassert([obj retainCount] == 1);

    id claimed = objc_claimAutoreleasedReturnValue(obj);
    testassert(claimed == obj);
    testassert([obj retainCount] == 2);
    [obj release];
    testassert([obj retainCount] == 1);

    // nil passes through.
    testassert(objc_claimAutoreleasedReturnValue(nil) == nil);

    // Via an autoreleased return, the claimed value survives the pool pop.
    void *pool = _objc_autoreleasePoolPush();
    id viaAutorelease = [[[TestObject alloc] init] autorelease];
    id owned = objc_claimAutoreleasedReturnValue(viaAutorelease);
    _objc_autoreleasePoolPop(pool);
    testassert([owned retainCount] == 1);
    [owned release];

    [obj release];
    succeed(__FILE__);
}
