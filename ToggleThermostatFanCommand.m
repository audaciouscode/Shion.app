//
//  ToggleThermostatFanCommand.m
//  Shion
//
//  Created by Chris Karr on 8/15/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "ToggleThermostatFanCommand.h"
#import "Shion.h"
#import "Thermostat.h"

@implementation ToggleThermostatFanCommand

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	if (device != nil)
	{
		NSString * string = nil;
		
		if ([device isKindOfClass:[Thermostat class]])
		{
			Thermostat * thermostat = (Thermostat *) device;
			
			BOOL fanState = [thermostat fanActive];
				
			[thermostat setFanState:(fanState == NO)];
				
			NSXMLElement * note = [NSXMLElement elementWithName:@"note"];
			[note setAttributesAsDictionary:[NSDictionary dictionaryWithObject:@"info" forKey:@"type"]];
			
			NSString * state = @"on";
			
			if (fanState)
				state = @"off";
			
			string = [NSString stringWithFormat:@"%@ fan toggled %@.", [device name], state];

			[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
		}
		else
		{
			string = [NSString stringWithFormat:@"%@ does not support toggling the fan. Try using another device.", [device name]];
			[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
		}
		
		[result setValue:string forKey:CMD_RESULT_DESC];
	}
	else
	{
		[result setValue:@"Please specify a device to toggle the fan." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
