//
//  DeviceStatusCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "DeviceStatusCommand.h"
#import "Shion.h"

#import "Lamp.h"
#import "Appliance.h"
#import "Chime.h"

@implementation DeviceStatusCommand

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	if (device != nil)
	{
		NSMutableString * string = [NSMutableString stringWithFormat:@"%@ details", [device name]];
		
		if ([device type] != nil)
			[string appendFormat:@"\nType: %@", [device type]];

		if ([device model] != nil)
			[string appendFormat:@"\nModel: %@", [device model]];

		if ([device valueForKey:@"state"] != nil)
			[string appendFormat:@"\nCurrent State: %@", [device valueForKey:@"state"]]; // TODO: Make constant!

		if ([device address] != nil)
			[string appendFormat:@"\nAddress: %@", [device address]];

		if ([device platform] != nil)
			[string appendFormat:@"\nPlatform: %@", [device platform]];

		if ([device isKindOfClass:[Lamp class]])
		{
			if ([[device address] length] > 3)
				[string appendString:@"\nAvailable commands: activate, deactivate, brighten, dim, set level, status"];
			else
				[string appendString:@"\nAvailable commands: activate, deactivate, brighten, dim, status"];
		}
		else if ([device isKindOfClass:[Appliance class]])
			[string appendString:@"\nAvailable commands: activate, deactivate, status"];
		else if ([device isKindOfClass:[Chime class]])
			[string appendString:@"\nAvailable commands: ring, status"];

		// TODO: Commands for other device types.
		
		[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
		[result setValue:string forKey:CMD_RESULT_DESC];
		[result setValue:[NSDictionary dictionaryWithDictionary:device] forKey:CMD_RESULT_VALUE];
	}
	else
	{
		[result setValue:@"Please specify a device to inspect." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
