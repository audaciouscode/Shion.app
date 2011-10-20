//
//  ListDevicesCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "ListDevicesCommand.h"
#import "Device.h"
#import "DeviceManager.h"

@implementation ListDevicesCommand

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	NSArray * devices = [[DeviceManager sharedInstance] devices]; 
	
	NSMutableString * string = [NSMutableString string];
	
	if ([devices count] > 0)
	{
		[string appendFormat:@"There are %d devices present. They are:", [devices count]];
		
		NSMutableArray * myDevices = [NSMutableArray array];
		
		NSEnumerator * iter = [devices objectEnumerator];
		Device * device = nil;
		while (device = [iter nextObject])
		{
			[string appendFormat:@"\n%@, %@", [device name], [device type]];
			
			NSDictionary * resultDevice = [NSDictionary dictionaryWithDictionary:device];
			[myDevices addObject:resultDevice];
		}

		[result setValue:myDevices forKey:CMD_RESULT_VALUE];
	}
	else
		[string appendString:@"There are no devices present. Perhaps you would like to set up a few?"];
	
	
	[result setValue:string forKey:CMD_RESULT_DESC];
	[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
	
	return result;
}

@end
