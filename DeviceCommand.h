//
//  DeviceCommand.h
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Command.h"
#import "Device.h"

@interface DeviceCommand : Command 
{
	Device * device;
}

- (void) setDevice:(Device *) newDevice;

@end
