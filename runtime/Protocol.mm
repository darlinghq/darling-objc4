/*
 * Copyright (c) 1999-2001, 2005-2007 Apple Inc.  All Rights Reserved.
 * 
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*
	Protocol.h
	Copyright 1991-1996 NeXT Software, Inc.
*/

#include "objc-private.h"

#undef id
#undef Class

#include <stdlib.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <mach-o/ldsyms.h>

#include "Protocol.h"
#include "NSObject.h"

// __IncompleteProtocol is used as the return type of objc_allocateProtocol().

// Old ABI uses NSObject as the superclass even though Protocol uses Object
// because the R/R implementation for class Protocol is added at runtime
// by CF, so __IncompleteProtocol would be left without an R/R implementation 
// otherwise, which would break ARC.

#ifdef DARLING
// see libdispatch
#if __has_attribute(objc_nonlazy_class)
#define NONLAZY_CLASS      __attribute__((objc_nonlazy_class))
#define NONLAZY_CLASS_LOAD
#else
#define NONLAZY_CLASS
#define NONLAZY_CLASS_LOAD + (void)load {}
#endif
#endif

@interface __IncompleteProtocol : NSObject
@end

#if __OBJC2__
#ifdef DARLING
NONLAZY_CLASS
#else
__attribute__((objc_nonlazy_class))
#endif
#endif
@implementation __IncompleteProtocol
#ifdef DARLING
NONLAZY_CLASS_LOAD
#endif
@end


#if __OBJC2__
#ifdef DARLING
NONLAZY_CLASS
#else
__attribute__((objc_nonlazy_class))
#endif
#endif
@implementation Protocol

#ifdef DARLING
NONLAZY_CLASS_LOAD
#endif

- (BOOL) conformsTo: (Protocol *)aProtocolObj
{
    return protocol_conformsToProtocol(self, aProtocolObj);
}

- (struct objc_method_description *) descriptionForInstanceMethod:(SEL)aSel
{
#if !__OBJC2__
    return lookup_protocol_method((struct old_protocol *)self, aSel, 
                                  YES/*required*/, YES/*instance*/, 
                                  YES/*recursive*/);
#else
    return method_getDescription(protocol_getMethod((struct protocol_t *)self, 
                                                     aSel, YES, YES, YES));
#endif
}

- (struct objc_method_description *) descriptionForClassMethod:(SEL)aSel
{
#if !__OBJC2__
    return lookup_protocol_method((struct old_protocol *)self, aSel, 
                                  YES/*required*/, NO/*instance*/, 
                                  YES/*recursive*/);
#else
    return method_getDescription(protocol_getMethod((struct protocol_t *)self, 
                                                    aSel, YES, NO, YES));
#endif
}

- (const char *)name
{
    return protocol_getName(self);
}

- (BOOL)isEqual:other
{
#if __OBJC2__
    // check isKindOf:
    Class cls;
    Class protoClass = objc_getClass("Protocol");
    for (cls = object_getClass(other); cls; cls = cls->getSuperclass()) {
        if (cls == protoClass) break;
    }
    if (!cls) return NO;
    // check equality
    return protocol_isEqual(self, other);
#else
    return [other isKindOf:[Protocol class]] && [self conformsTo: other] && [other conformsTo: self];
#endif
}

#if __OBJC2__
- (NSUInteger)hash
{
    return 23;
}
#else
- (unsigned)hash
{
    return 23;
}
#endif

@end
