//
//  Appliance.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Appliance.h"

#import "DeviceManager.h"

#import "Shion.h"
#import <Shion/ASToggleDevice.h>
#import <Shion/ASDeviceController.h>

#import "EventManager.h"

@implementation Appliance

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Appliance" forKey:TYPE];
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
		asDevice = [[ASToggleDevice alloc] init];
		
		[self setObject:asDevice forKey:FRAMEWORK_DEVICE];
		[asDevice release];
		
		[self setAddress:[self address]];
		
		return [self device];
	}	
}

- (id) valueForKey:(NSString *) key
{
	if ([key isEqual:USER_DEVICE_LEVEL])
		return [self valueForKey:DEVICE_LEVEL];
	else
		return [super valueForKey:key];
}

- (NSDictionary *) snapshotValues
{
	if ([self valueForKey:USER_DEVICE_LEVEL] != nil)
		return [NSDictionary dictionaryWithObject:[self valueForKey:USER_DEVICE_LEVEL] forKey:USER_DEVICE_LEVEL];
	else
		return [NSDictionary dictionary];
}


- (void) setValue:(id) value forKey:(NSString *) key
{
	if ([key isEqual:DEVICE_LEVEL])
	{
		// Non-user initiated...
		
		[self willChangeValueForKey:USER_DEVICE_LEVEL];

		NSManagedObject * lastEvent = [[EventManager sharedInstance] lastUpdateForIdentifier:[self identifier] event:nil];
		
		if (![[lastEvent valueForKey:@"value"] isEqual:[value description]])
		{
			NSNumber * level = (NSNumber *) value;
		
			NSString * message = [NSString stringWithFormat:@"%@ is fully activated.", [self name]];
		
			if ([level intValue] == 0)
				message = [NSString stringWithFormat:@"%@ is fully deactivated.", [self name]];
		
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
										   description:message value:[level description]];
		}
		
		[super setValue:value forKey:key];

		[self didChangeValueForKey:USER_DEVICE_LEVEL];
	}
	else if ([key isEqual:USER_DEVICE_LEVEL])
	{
		// User initiated...
		
		NSNumber * level = (NSNumber *) value;
		
		if ([level intValue] == 0)
		{
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
										   description:[NSString stringWithFormat:@"The user deactivated %@.", [self name]]
												 value:@"0"];
			
			[self setActive:NO];
		}
		else 
		{
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
										   description:[NSString stringWithFormat:@"The user activated %@.", [self name]]
												 value:@"255"];

			[self setActive:YES];
		}
	}
	else
		[super setValue:value forKey:key];
}

- (void) setActive:(BOOL) active
{
	[self willChangeValueForKey:LAST_UPDATE];
	[self willChangeValueForKey:USER_DEVICE_LEVEL];

	NSNumber * value = [NSNumber numberWithInt:0];
	
	if (active)
		value = [NSNumber numberWithInt:255];
	
	[self setValue:value forKey:DEVICE_LEVEL];

	if ([self armed])
	{
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
	
		[command setValue:[self device] forKey:DEVICE];
	
		if (active)
			[command setValue:[NSNumber numberWithUnsignedInt:AS_ACTIVATE] forKey:DEVICE_COMMAND];
		else
			[command setValue:[NSNumber numberWithUnsignedInt:AS_DEACTIVATE] forKey:DEVICE_COMMAND];
	
		[[DeviceManager sharedInstance] sendCommand:command];
	}

	[self didChangeValueForKey:USER_DEVICE_LEVEL];
	[self didChangeValueForKey:LAST_UPDATE];
}

- (BOOL) active
{
	return ([[self level] intValue] > 0);
}

- (NSNumber *) level
{
	return [self valueForKey:DEVICE_LEVEL];
}

- (NSString *) snapshotDescription:(NSDictionary *) snapValues
{
	NSNumber * level = [snapValues valueForKey:USER_DEVICE_LEVEL];
	
	if (level != nil)
	{
		if ([level intValue] > 0)
			return @"On";
		
		return @"Off";
	}
	
	return @"Unknown state for appliance.";
}

- (void) activate:(NSScriptCommand *) command
{
	[self setActive:YES];
}

- (void) deactivate:(NSScriptCommand *) command
{
	[self setActive:NO];
}

@end
