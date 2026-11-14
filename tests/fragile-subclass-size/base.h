// Copyright (C) 2026 Lubos Dolezel
//
// Fragile base class for main.m: the library defines it with more ivars than main.m's BASE_V1 view.
#import <Foundation/Foundation.h>
// Version of the base class the client was compiled against (BASE_V1)
// or the version the library really has (default: grown by two ivars).
@interface FragileBase : NSObject
{
	int a;
#ifndef BASE_V1
	int b;
	int c;
	int d;
	int e;
#endif
}
- (void) fill;
- (int) sum;
@end
