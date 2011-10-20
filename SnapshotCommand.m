//
//  SnapshotCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "SnapshotCommand.h"

@implementation SnapshotCommand

- (void) setSnaphot:(Snapshot *) newSnapshot
{
	if (snapshot != nil)
		[snapshot release];
	
	snapshot = [newSnapshot retain];
}

- (void) dealloc
{
	[snapshot release];
	
	[super dealloc];
}

@end
