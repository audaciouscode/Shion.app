//
//  GroupInterfaceDeviceCommandAction.m
//  Shion
//
//  Created by Chris Karr on 9/17/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "GraphInterfaceDeviceCommandAction.h"


@implementation GraphInterfaceDeviceCommandAction

- (void) setDevice:(DeviceDictionary *) newDevice
{
	if (device != nil)
		[device release];
	
	device = [newDevice retain];
}

- (void) setCommand:(unsigned char) newCommand
{
	command = newCommand;
}

- (void) execute
{
	switch (command) 
	{
		case GRAPH_ACTIVATE:
			[device setValue:[NSNumber numberWithInt:255] forKey:TOGGLE_STATE];
			break;
		case GRAPH_DEACTIVATE:
			[device setValue:[NSNumber numberWithInt:0] forKey:TOGGLE_STATE];
			break;
		case GRAPH_BRIGHTEN:
			[device setValue:[NSNumber numberWithBool:YES] forKey:BRIGHTEN_STATE];
			break;
		case GRAPH_DIM:
			[device setValue:[NSNumber numberWithBool:YES] forKey:DIM_STATE];
			break;
		default:
			break;
	}
}

// 
// TODO: dealloc

@end
