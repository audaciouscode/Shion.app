//
//  BrightenDeviceCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "BrightenDeviceCommand.h"
#import "Shion.h"

#import "Lamp.h"

@implementation BrightenDeviceCommand

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	if (device != nil)
	{
		NSString * string = nil;
		
		if ([device isKindOfClass:[Lamp class]])
		{
			Lamp * lamp = (Lamp *) device;
			
			[lamp brighten:nil];
			
			string = [NSString stringWithFormat:@"Brightening %@..", [device name]];
			[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
		}
		else
		{
			string = [NSString stringWithFormat:@"Unable to brighten %@. Are you certain that this is the right device?", [device name]];
			[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
		}
		
		[result setValue:string forKey:CMD_RESULT_DESC];
	}
	else
	{
		[result setValue:@"Please specify a device to brighten." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
