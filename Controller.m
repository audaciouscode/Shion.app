//
//  Controller.m
//  Shion
//
//  Created by Chris Karr on 4/7/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ASPowerLinc2412Controller.h"

#import "Controller.h"
#import "DeviceManager.h"
#import "EventManager.h"
#import "NotificationManager.h"

#import "Shion.h"

#define DEVICE_CONTROLLER @"device_controller"

@implementation Controller

+ (Controller *) controller;
{
	return [Controller dictionary];
}

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Controller" forKey:TYPE];
		
		lastStatus = -1;
		
		statusTimer = [[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(calculateStatus:) userInfo:nil repeats:YES] retain];
		resetTimer = nil;
		closeTimer = nil;
	}
	
	return self;
}

- (float) networkState
{
	return lastStatus;
}

- (void) calculateStatus:(NSTimer *) theTimer
{
	NSArray * devices = [[DeviceManager sharedInstance] devices];
	
	unsigned int count = 0;
	float sum = 0;
	
	NSEnumerator * iter = [devices objectEnumerator];
	Device * device = nil;
	while (device = [iter nextObject])
	{
		if ([[self platform] isEqual:@"X10"] && ![[device platform] isEqual:@"X10"])
		{
			// Skip
		}
		else if ([device checksStatus])
		{
			count += 1;
			
			if ([device responsive])
				sum += 1;
			else
			{
				NSDate * lastUpdate = [device valueForKey:@"last_unresponsive_note"];
				
				if (lastUpdate == nil)
					lastUpdate = [NSDate distantPast];
				
				if ([lastUpdate timeIntervalSinceNow] < (-60 * 60))
				{
					[[NotificationManager sharedInstance] showMessage:[NSString stringWithFormat:@"%@ is unresponsive.", [device name]]
																title:[device name] icon:nil type:HARDWARE_NOTE];
					
					[device setValue:[NSDate date] forKey:@"last_unresponsive_note"];
				}
			}
		}
	}
	
	if (count > 0)
	{
		sum = sum / count;

		lastStatus = sum;
		
		[[EventManager sharedInstance] createEvent:@"device" source:@"Controller" initiator:@"Controller"
									   description:[NSString stringWithFormat:@"The network (%@) is %0.0f%% responsive.", [self name],
													(sum * 100)]
											 value:[NSString stringWithFormat:@"%f", (sum * 255)]];

		NSNumber * threshold = [[NSUserDefaults standardUserDefaults] valueForKey:@"controller_reset_threshold"];
		
		if (threshold == nil)
			threshold = [NSNumber numberWithFloat:15];
		
		if (sum < ([threshold floatValue] / 100) && closeTimer == nil && resetTimer == nil)
			closeTimer = [[NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(closeTimer:) userInfo:nil repeats:NO] retain];
		else if (sum >= 0.15 && closeTimer != nil && resetTimer == nil)
		{
			[closeTimer invalidate];
			[closeTimer release];
			closeTimer = nil;
		}
	}
	else
		lastStatus = -1;
}

- (void) resetTimer:(NSTimer *) theTimer
{
	[[self deviceController] resetController];
	
	[resetTimer invalidate];
	[resetTimer release];
	
	resetTimer = nil;
}

- (void) closeTimer:(NSTimer *) theTimer
{
	[[self deviceController] closeController];
	
	[closeTimer invalidate];
	[closeTimer release];
	
	closeTimer = nil;
	
	resetTimer = [[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(resetTimer:) userInfo:nil repeats:NO] retain];
}

- (void) setDeviceController:(ASDeviceController *) controller
{
	[self setValue:controller forKey:DEVICE_CONTROLLER];
}

- (ASDeviceController *) deviceController
{
	return [self valueForKey:DEVICE_CONTROLLER];
}

- (NSData *) data
{
	// Do not persist to disk.
	
	return nil;
}

- (BOOL) checksStatus
{
	return NO;
}

- (void) setValue:(id)value forKey:(NSString *)key
{
	if ([key isEqual:@"start_link"])
	{
		ASDeviceController * deviceController = [self deviceController];
		
		if ([deviceController isKindOfClass:[ASPowerLinc2412Controller class]])
		{
			ASPowerLinc2412Controller * serialInsteon = (ASPowerLinc2412Controller *) deviceController;
			
			[serialInsteon cancelAllLink];
			[serialInsteon startAllLink];
		}
	}
	else if ([key isEqual:@"stop_link"])
	{
		ASDeviceController * deviceController = [self deviceController];
		
		if ([deviceController isKindOfClass:[ASPowerLinc2412Controller class]])
		{
			ASPowerLinc2412Controller * serialInsteon = (ASPowerLinc2412Controller *) deviceController;
			
			[serialInsteon startAllLink];
		}
	}
	else
		[super setValue:value forKey:key];
}


@end
