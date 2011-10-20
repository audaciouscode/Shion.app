//
//  SetThermostatHeatPointCommand.m
//  Shion
//
//  Created by Chris Karr on 8/15/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "SetThermostatHeatPointCommand.h"
#import "Shion.h"

#import "Thermostat.h"

@implementation SetThermostatHeatPointCommand

- (void) setHeat:(int) heatPoint
{
	heat = heatPoint;
}

- (id) init;
{
	if (self = [super init])
		heat = -1;
	
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

			if (heat > 0 && heat < 100)
			{
				[thermostat setHeatPoint:[NSNumber numberWithInt:heat]];
				string = [NSString stringWithFormat:@"%@ heat point set to %d°.", [device name], heat];
				
				[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
			}
			else
			{
				string = @"Please enter a heat point between 1° and 100°.";
				[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
			}
			
		}
		else
		{
			string = [NSString stringWithFormat:@"%@ does not support setting the heat point. Try using another device.", [device name]];
			[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
		}
		
		[result setValue:string forKey:CMD_RESULT_DESC];
	}
	else
	{
		[result setValue:@"Please specify a device to set the heat point." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
