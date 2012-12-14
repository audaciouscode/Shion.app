//
//  House.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "House.h"
#import "Shion.h"
#import "DeviceManager.h"
#import "EventManager.h"
#import "Lamp.h"
#import "Appliance.h"

#import "ASHouseDevice.h"
#import "ASDeviceController.h"

#define DEVICE_LIGHTS_ON @"device_lights_on"
#define DEVICE_LIGHTS_OFF @"device_lights_off"
#define DEVICE_ALL_OFF @"device_all_off"

@implementation House

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"House" forKey:TYPE];
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
		asDevice = [[ASHouseDevice alloc] init];
		
		[self setObject:asDevice forKey:FRAMEWORK_DEVICE];
		[asDevice release];
		
		[self setAddress:[self address]];
		
		return [self device];
	}	
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	[super setValue:value forKey:key];
	
	if ([key isEqual:DEVICE_LIGHTS_ON])
		[self activateLights];
	else if ([key isEqual:DEVICE_LIGHTS_OFF])
		[self deactivateLights];
	else if ([key isEqual:DEVICE_ALL_OFF])
		[self deactivateAll];
}

- (NSArray *) devices
{
	NSMutableArray * devices = [NSMutableArray array];
	
	NSEnumerator * iter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * device = nil;
	while (device = [iter nextObject])
	{
		if ([[device platform] isEqual:PLATFORM_X10])
		{
			if (self != device && [[device address] hasPrefix:[self address]])
				[devices addObject:device];
		}
	}
	
	return devices;
}

- (void) allLightsOff:(NSScriptCommand *) command
{
	[self deactivateLights];
}

- (void) deactivateLights
{
	if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_ALL_LIGHTS_OFF] forKey:DEVICE_COMMAND];
		
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user deactivated all lights in %@.", [self name]]
											 value:@"0"];
		
		NSEnumerator * iter = [[self devices] objectEnumerator];
		Device * device = nil;
		while (device = [iter nextObject])
		{
			if ([device isKindOfClass:[Lamp class]])
				[device setValue:[NSNumber numberWithInt:0] forKey:DEVICE_LEVEL];
		}
		
		[self didChangeValueForKey:LAST_UPDATE];
	}
}

- (void) allLightsOn:(NSScriptCommand *) command
{
	[self activateLights];
}

- (void) activateLights
{
	if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_ALL_LIGHTS_ON] forKey:DEVICE_COMMAND];
		
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user activated all lights in %@.", [self name]]
											 value:@"0"];

		NSEnumerator * iter = [[self devices] objectEnumerator];
		Device * device = nil;
		while (device = [iter nextObject])
		{
			if ([device isKindOfClass:[Lamp class]])
				[device setValue:[NSNumber numberWithInt:255] forKey:DEVICE_LEVEL];
		}
		
		[self didChangeValueForKey:LAST_UPDATE];
	}
}

- (void) allOff:(NSScriptCommand *) command
{
	[self deactivateAll];
}

- (void) deactivateAll
{
	if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_ALL_UNITS_OFF] forKey:DEVICE_COMMAND];
		
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user deactivated all devices in %@.", [self name]]
											 value:@"0"];

		NSEnumerator * iter = [[self devices] objectEnumerator];
		Device * device = nil;
		while (device = [iter nextObject])
		{
			if ([device isKindOfClass:[Appliance class]])
				[device setValue:[NSNumber numberWithInt:0] forKey:DEVICE_LEVEL];
		}
		
		[self didChangeValueForKey:LAST_UPDATE];
	}
}

@end
