//
//  DeviceCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "DeviceCommand.h"


@implementation DeviceCommand

- (void) setDevice:(Device *) newDevice
{
	if (device != nil)
		[device release];
	
	device = [newDevice retain];
}

- (void) dealloc
{
	if (device != nil)
		[device release];
	
	[super dealloc];
}

@end
