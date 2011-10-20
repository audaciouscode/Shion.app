//
//  ASMutableDictionary.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ASMutableDictionary : NSMutableDictionary
{
	NSMutableDictionary * store;

	BOOL dirty;
}

- (BOOL) isDirty;
- (void) clearDirty;

@end
