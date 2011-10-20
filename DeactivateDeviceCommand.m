//
//  DeactivateDeviceCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "DeactivateDeviceCommand.h"
#import "Shion.h"

#import "Appliance.h"

@implementation DeactivateDeviceCommand

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	if (device != nil)
	{
		NSString * string = nil;
		
		if ([device isKindOfClass:[Appliance class]])
		{
			Appliance * appliance = (Appliance *) device;
			
			[appliance setActive:NO];
			string = [NSString stringWithFormat:@"Turning off %@...", [device name]];
			[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
		}
		else
		{
			string = [NSString stringWithFormat:@"Unable to deactivate %@. Are you certain that this is the right device?", [device name]];
			[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
		}
		
		[result setValue:string forKey:CMD_RESULT_DESC];
	}
	else
	{
		[result setValue:@"Please specify a device to deactivate." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
