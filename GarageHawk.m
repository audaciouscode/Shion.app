//
//  GarageHawk.m
//  Shion
//
//  Created by Chris Karr on 10/8/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "GarageHawk.h"

#import <Shion/ASDeviceController.h>
#import <Shion/ASGarageHawkDevice.h>

#import "Shion.h"
#import "DeviceManager.h"
#import "EventManager.h"

@implementation GarageHawk

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:GARAGE_HAWK forKey:TYPE];
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
		asDevice = [[ASGarageHawkDevice alloc] init];
		
		[self setObject:asDevice forKey:FRAMEWORK_DEVICE];
		[asDevice release];
		
		[self setAddress:[self address]];
		
		return [self device];
	}	
}

- (void) close
{
	NSMutableDictionary * command = [NSMutableDictionary dictionary];
	
	[command setValue:[self device] forKey:DEVICE];
	
	[command setValue:[NSNumber numberWithUnsignedInt:AS_GARAGE_CLOSE] forKey:DEVICE_COMMAND];
	
	[[DeviceManager sharedInstance] sendCommand:command];
}

- (BOOL) isClosed
{
	Event * event = [[[EventManager sharedInstance] eventsForIdentifier:[self identifier] event:@"device"] lastObject];
	
	if (event != nil && [[event value] intValue] == 0)
		return YES;
	else
		return NO;
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	if ([key isEqual:@"do_close"])
	{
		[self close];
		
		NSString * message = [NSString stringWithFormat:@"Closing garage door."];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
									   description:message value:[NSNumber numberWithInt:255]];
	}
	else
		[super setValue:value forKey:key];
}

@end
