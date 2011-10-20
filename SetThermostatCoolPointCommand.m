//
//  SetThermostatCoolPointCommand.m
//  Shion
//
//  Created by Chris Karr on 8/15/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "SetThermostatCoolPointCommand.h"
#import "Shion.h"

#import "Thermostat.h"

@implementation SetThermostatCoolPointCommand

- (void) setCool:(int) coolPoint
{
	cool = coolPoint;
}

- (id) init;
{
	if (self = [super init])
		cool = -1;
	
	return self;
}

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	if (device != nil)
	{
		NSString * string = nil;
		
		if ([device isKindOfClass:[Thermostat class]])
		{
			Thermostat * thermostat = (Thermostat *) device;

			if (cool > 0 && cool < 100)
			{
				[thermostat setCoolPoint:[NSNumber numberWithInt:cool]];

				string = [NSString stringWithFormat:@"%@ cool point set to %d°.", [device name], cool];

				[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
			}
			else
			{
				string = @"Please enter a cool point between 1° and 100°.";
				[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
			}
				
		}
		else
		{
			string = [NSString stringWithFormat:@"%@ does not support setting the cool point. Try using another device.", [device name]];
			[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
		}
		
		[result setValue:string forKey:CMD_RESULT_DESC];
	}
	else
	{
		[result setValue:@"Please specify a device to set the cool point." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
