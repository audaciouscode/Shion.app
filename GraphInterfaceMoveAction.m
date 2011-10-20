//
//  GraphInterfaceMoveAction.m
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "GraphInterfaceMoveAction.h"


@implementation GraphInterfaceMoveAction

- (id) init
{
	if (self = [super init])
		destination = nil;
	
	return self;
}

- (void) setDestinationNode:(GraphInterfaceNode *) newDestination
{
	if (destination != nil)
		[destination release];
	
	destination = [newDestination retain];
}

- (void) execute
{
	if (destination != nil)
	{
		GraphInterface * interface = [destination interface];
		
		[interface advanceTo:destination];
	}
	else 
	{
		// TODO: Errors?
	}

}

@end
