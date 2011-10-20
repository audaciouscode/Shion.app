//
//  RemoteBuddyManager.m
//  Shion
//
//  Created by Chris Karr on 5/11/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "RemoteBuddyManager.h"


@implementation RemoteBuddyManager

- (id)init
{
	if (self = [super init])
		behaviourBridgeReceptor = [[BehaviourBridgeReceptor alloc] initWithDelegate:self];
	
	return self;
}

- (void)dealloc
{
	[behaviourBridgeReceptor release];
	behaviourBridgeReceptor = nil;
	
	[super dealloc];
}

@end
