//
//  SetThermostatModeCommand.m
//  Shion
//
//  Created by Chris Karr on 8/15/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "SetThermostatModeCommand.h"
#import "Shion.h"
#import "ASThermostatDevice.h"
#import "Thermostat.h"

@implementation SetThermostatModeCommand

- (id) init;
{
	if (self = [super init])
		mode = @"auto";
	
	return self;
}

-(void) setMode:(NSString *) newMode
{
	if (mode != nil)
		[mode release];
	
	mode = [newMode retain];
}

- (void) dealloc
{
	if (mode != nil)
		[mode release];
	
	[super dealloc];
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
			
			if ([mode rangeOfString:@"off"].location != NSNotFound)
				[thermostat setMode:@"Off"];
			else if ([mode rangeOfString:@"program heat"].location != NSNotFound)
				[thermostat setMode:@"Program Heat"];
			else if ([mode rangeOfString:@"program cool"].location != NSNotFound)
				[thermostat setMode:@"Program Cool"];
			else if ([mode rangeOfString:@"heat"].location != NSNotFound)
				[thermostat setMode:@"Heat"];
			else if ([mode rangeOfString:@"cool"].location != NSNotFound)
				[thermostat setMode:@"Cool"];
			else if ([mode rangeOfString:@"program"].location != NSNotFound)
				[thermostat setMode:@"Program"];
			else
				[thermostat setMode:@"Auto"];

			string = [NSString stringWithFormat:@"Setting %@ mode to '%@'...", [device name], mode];
			[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
		}
		else
		{
			string = [NSString stringWithFormat:@"%@ does not support setting the mode. Try using another device.", [device name]];
			[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
		}
		
		[result setValue:string forKey:CMD_RESULT_DESC];
	}
	else
	{
		[result setValue:@"Please specify a device to set thermostat mode." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
