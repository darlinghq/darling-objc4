// Copyright (C) 2026 Lubos Dolezel
//
// Fragile base class for main.m: the library defines it with more ivars than main.m's BASE_V1 view.
#import "base.h"
@implementation FragileBase
- (void) fill { a = 1;
#ifndef BASE_V1
	b = 2; c = 3; d = 4; e = 5;
#endif
}
- (int) sum { return a
#ifndef BASE_V1
	+ b + c + d + e
#endif
	; }
@end
