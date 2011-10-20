//
//  Lock.m
//  Shion
//
//  Created by Chris Karr on 7/6/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "Lock.h"

#import <Shion/ASDeviceController.h>
#import <Shion/ASLockDevice.h>

#import "Shion.h"
#import "DeviceManager.h"
#import "EventManager.h"

@implementation Lock

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:LOCK forKey:TYPE];
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
		asDevice = [[ASLockDevice alloc] init];
		
		[self setObject:asDevice forKey:FRAMEWORK_DEVICE];
		[asDevice release];
		
		[self setAddress:[self address]];
		
		return [self device];
	}	
}

- (void) lock
{
	NSMutableDictionary * command = [NSMutableDictionary dictionary];
	
	[command setValue:[self device] forKey:DEVICE];
	
	[command setValue:[NSNumber numberWithUnsignedInt:AS_LOCK] forKey:DEVICE_COMMAND];
	
	[[DeviceManager sharedInstance] sendCommand:command];
}

- (void) unlock
{
	NSMutableDictionary * command = [NSMutableDictionary dictionary];
	
	[command setValue:[self device] forKey:DEVICE];
	
	[command setValue:[NSNumber numberWithUnsignedInt:AS_UNLOCK] forKey:DEVICE_COMMAND];
	
	[[DeviceManager sharedInstance] sendCommand:command];
	
}

- (BOOL) isLocked
{
	Event * event = [[[EventManager sharedInstance] eventsForIdentifier:[self identifier] event:@"device"] lastObject];
	
	if (event != nil && [[event value] intValue] > 255)
		return YES;
	else
		return NO;
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	if ([key isEqual:@"do_lock"])
	{
		[self lock];
		
		NSString * message = [NSString stringWithFormat:@"Activated lock."];
			
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
									   description:message value:[NSNumber numberWithInt:255]];
	}
	else if ([key isEqual:@"do_unlock"])
	{
		[self unlock];
		
		NSString * message = [NSString stringWithFormat:@"Deactivated lock."];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
									   description:message value:[NSNumber numberWithInt:0]];
	}
	else
		[super setValue:value forKey:key];
}

- (BOOL) checksStatus
{
	return NO;
}


@end
