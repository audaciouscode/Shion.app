//
//  SetDeviceLevelCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "SetDeviceLevelCommand.h"
#import "Shion.h"

#import "Lamp.h"

@implementation SetDeviceLevelCommand

- (id) init;
{
	if (self = [super init])
		level = -1;

	return self;
}

-(void) setLevel:(int) deviceLevel
{
	level = deviceLevel;
}

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	if (device != nil)
	{
		NSString * string = nil;
		
		if ([device isKindOfClass:[Lamp class]])
		{
			Lamp * lamp = (Lamp *) device;
			
			if (![device checksStatus])
			{
				string = [NSString stringWithFormat:@"%@ does not support setting the level. Try using the 'dim' or 'brighten' commands.", [device name]];
				[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
			}
			else
			{
				if (level < 0 || level > 8)
				{
					string = @"Please provide a level between 0 and 8...";
					[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
				}
				else
				{
					int realLevel = (level * 32) - 1;
					
					if (realLevel < 0)
						realLevel = 0;
					
					[lamp setLevel:[NSNumber numberWithInt:realLevel]];
				
					int percent = (level * 100) / 8;
				
					string = [NSString stringWithFormat:@"Setting %@ to %d%%...", [device name], percent];
					[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
				}
			}
		}
		else
		{
			string = [NSString stringWithFormat:@"%@ does not support setting the level. Try using another device.", [device name]];
			[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
		}
		
		[result setValue:string forKey:CMD_RESULT_DESC];
	}
	else
	{
		[result setValue:@"Please specify a device to set light level." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
