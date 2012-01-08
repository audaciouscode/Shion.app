//
//  Lamp.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Lamp.h"

#import "Shion.h"
#import "DeviceManager.h"
#import "EventManager.h"

#import <Shion/ASDeviceController.h>
#import <Shion/ASContinuousDevice.h>

#define LAMP_DIM @"lamp_dim"
#define LAMP_BRIGHTEN @"lamp_brighten"

@implementation Lamp

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
		[self setValue:@"Lamp" forKey:TYPE];
	
	return self;
}

- (ASDevice *) device
{
	ASDevice * asDevice = [self valueForKey:FRAMEWORK_DEVICE];
	
	if (asDevice != nil)
		return asDevice;
	else
	{
		asDevice = [[ASContinuousDevice alloc] init];
		
		[self setObject:asDevice forKey:FRAMEWORK_DEVICE];
		[asDevice release];
		
		[self setAddress:[self address]];
		
		return [self device];
	}	
}

- (NSString *) snapshotDescription:(NSDictionary *) snapValues
{
	NSNumber * level = [snapValues valueForKey:USER_DEVICE_LEVEL];
	
	if (level != nil)
	{
		float percentage = (([level intValue] + 1) * 100.0) / 256;
		
		return [NSString stringWithFormat:@"%0.0f%% Strength", percentage];
	}
	
	return @"Unknown state for lamp.";
}

- (void) dim
{
	if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_DECREASE] forKey:DEVICE_COMMAND];
		
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user dimmed %@.", [self name]]
											 value:@"255"];
		
		[self didChangeValueForKey:LAST_UPDATE];
	}
}

- (void) brighten
{
	if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_INCREASE] forKey:DEVICE_COMMAND];
		
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user brightened %@.", [self name]]
											 value:@"255"];
		
		[self didChangeValueForKey:LAST_UPDATE];
	}
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	if ([key isEqual:DEVICE_LEVEL])
	{
		// Non-user initiated...
		
		NSNumber * level = (NSNumber *) value;
		float percentage = (([level intValue] + 1) * 100.0) / 256;
		
		[self willChangeValueForKey:USER_DEVICE_LEVEL];
		
		NSString * message = [NSString stringWithFormat:@"%@ is at %0.0f%% strength.", [self name], percentage];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
									   description:message value:[level description]];
		
		// ???
		
		[super setValue:value forKey:key];
		
		[self didChangeValueForKey:USER_DEVICE_LEVEL];
	}
	else if ([key isEqual:USER_DEVICE_LEVEL])
	{
		// User initiated...
		
		NSNumber * level = (NSNumber *) value;
		float percentage = (([level intValue] + 1) * 100.0) / 256;
		
		[self willChangeValueForKey:USER_DEVICE_LEVEL];
		
		NSString * message = [NSString stringWithFormat:@"User set %@ to %0.0f%% strength.", [self name], percentage];
		
		[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:@"User"
									   description:message value:[level description]];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_SET_LEVEL] forKey:DEVICE_COMMAND];
		[command setValue:level forKey:COMMAND_VALUE];
		
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[super setValue:value forKey:DEVICE_LEVEL];
		
		[self didChangeValueForKey:USER_DEVICE_LEVEL];
	}
	else if ([key isEqual:LAMP_BRIGHTEN])
	{
		[self brighten];
	
		[self willChangeValueForKey:LAMP_BRIGHTEN];
		[self didChangeValueForKey:LAMP_BRIGHTEN];
	}
	else if ([key isEqual:LAMP_DIM])
	{
		[self dim];

		[self willChangeValueForKey:LAMP_DIM];
		[self didChangeValueForKey:LAMP_DIM];
	}
	else
		[super setValue:value forKey:key];
}

- (void) setLevel:(NSNumber *) level
{
	return [self setValue:level forKey:USER_DEVICE_LEVEL];
}

- (id) valueForKey:(NSString *)key
{
	if ([key isEqual:LAMP_BRIGHTEN])
		return [NSNumber numberWithBool:NO];
	else if ([key isEqual:LAMP_DIM])
		return [NSNumber numberWithBool:NO];
	else
		return [super valueForKey:key];
}

- (void) dim:(id) sender
{
	if ([[self platform] isEqual:@"X10"])
		[self dim];
	else
	{
		int level = [[self level] intValue];
		
		level = level - 32;
		
		if (level < 0)
			level = 0;
		
		[self setLevel:[NSNumber numberWithInt:level]];
	}
}

- (void) brighten:(id) sender
{
	if ([[self platform] isEqual:@"X10"])
		[self brighten];
	else
	{
		int level = [[self level] intValue];
		
		level = level + 32;
		
		if (level > 255)
			level = 255;
		
		[self setLevel:[NSNumber numberWithInt:level]];
	}
}

@end
