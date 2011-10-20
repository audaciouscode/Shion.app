//
//  GroupInterfaceDeviceCommandAction.h
//  Shion
//
//  Created by Chris Karr on 9/17/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GraphInterfaceAction.h"
#import "DeviceDictionary.h"

#define GRAPH_ACTIVATE 0x01
#define GRAPH_DEACTIVATE 0x02
#define GRAPH_BRIGHTEN 0x03
#define GRAPH_DIM 0x04

@interface GraphInterfaceDeviceCommandAction : GraphInterfaceAction 
{
	DeviceDictionary * device;
	unsigned char command;
}

- (void) setDevice:(DeviceDictionary *) newDevice;
- (void) setCommand:(unsigned char) newCommand;

@end
