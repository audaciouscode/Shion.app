//
//  Chime.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Chime.h"

#import "DeviceManager.h"

#import "Shion.h"
#import "ASChimeDevice.h"
#import "ASDeviceController.h"

#import "EventManager.h"

#define DEVICE_CHIME @"device_chime"

@implementation Chime

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Chime" forKey:TYPE];
	}
	
	return self;
}

- (ASDevice *) device
{
	ASDevice * asDevice = [self valueForKey:FRAMEWORK_DEVICE];
	
	if (asDevice != nil)
		return asDevice;
	else
	{
		asDevice = [[ASChimeDevice alloc] init];
		
		[self setObject:asDevice forKey:FRAMEWORK_DEVICE];
		[asDevice release];
		
		[self setAddress:[self address]];
		
		return [self device];
	}	
}

- (void) chime
{
	if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_CHIME] forKey:DEVICE_COMMAND];

		[[DeviceManager sharedInstance] sendCommand:command];

		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user began ringing %@.", [self name]]
											 value:@"65535"];

		[[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(expireChime:) userInfo:nil repeats:NO] retain];

		[self didChangeValueForKey:LAST_UPDATE];
	}
}

- (void) expireChime:(NSTimer *) theTimer
{
	[theTimer release];

	[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
								   description:[NSString stringWithFormat:@"%@ finished ringing.", [self name]]
										 value:@"0"];
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	[super setValue:value forKey:key];

	if ([key isEqual:DEVICE_CHIME])
		[self chime];
}

- (BOOL) checksStatus
{
	return NO;
}

- (void) chime:(NSScriptCommand *) command
{
	[self chime];
}

@end
