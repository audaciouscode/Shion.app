//
//  GraphInterfaceCompoundAction.m
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "GraphInterfaceCompoundAction.h"


@implementation GraphInterfaceCompoundAction

- (id) init
{
	if (self = [super init])
		actions = [[NSMutableArray alloc] init];
	
	return self;
}

- (void) addAction:(GraphInterfaceAction *) action
{
	[actions addObject:action];
}

- (void) dealloc
{
	[actions release];
	
	[super dealloc];
}

- (void) execute
{
	NSEnumerator * iter = [actions objectEnumerator];
	GraphInterfaceAction * action = nil;
	while (action = [iter nextObject])
	{
		[action execute];
	}
}

@end
