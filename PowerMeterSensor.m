//
//  PowerMeterSensor.m
//  Shion
//
//  Created by Chris Karr on 7/4/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "PowerMeterSensor.h"

#import "ASDeviceController.h"
#import "ASPowerMeterDevice.h"

#import "Shion.h"

#import "EventManager.h"
#import "DeviceManager.h"

@implementation PowerMeterSensor

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Power Meter Sensor" forKey:TYPE];
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
		asDevice = [[ASPowerMeterDevice alloc] init];
		
		[self setObject:asDevice forKey:FRAMEWORK_DEVICE];
		[asDevice release];
		
		[self setAddress:[self address]];
		
		return [self device];
	}	
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	// TODO: Reset... (reset_usage)
	
	if ([key isEqual:POWER_LEVEL])
	{
		[self willChangeValueForKey:POWER_LEVEL];
		
		NSManagedObject * lastEvent = [[EventManager sharedInstance] lastUpdateForIdentifier:[self identifier] event:@"device"];
		
		if (![[lastEvent valueForKey:@"value"] isEqual:[value description]])
		{
			NSString * message = [NSString stringWithFormat:@"Currently using %@ watts.", [value description]];
			
			[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
										   description:message value:[value description]];
		}
		
		[super setValue:value forKey:key];
		
		[self didChangeValueForKey:POWER_LEVEL];
	}
	else if ([key isEqual:@"reset_usage"])
	{
		if ([self armed])
		{
			[self willChangeValueForKey:LAST_UPDATE];
			
			NSMutableDictionary * command = [NSMutableDictionary dictionary];
			
			[command setValue:[self device] forKey:DEVICE];
			
			[command setValue:[NSNumber numberWithUnsignedInt:AS_RESET_POWER_METER] forKey:DEVICE_COMMAND];
			
			[[DeviceManager sharedInstance] sendCommand:command];

			[[EventManager sharedInstance] createEvent:@"device_total" source:[self identifier] initiator:@"User"
										   description:[NSString stringWithFormat:@"The user reset %@ cumulative power total.", [self name]]
												 value:@"0"];
			
			[self didChangeValueForKey:LAST_UPDATE];
			
			[self willChangeValueForKey:POWER_TOTAL];

			[super setValue:[NSNumber numberWithUnsignedInt:0] forKey:POWER_TOTAL];
			
			[self didChangeValueForKey:POWER_TOTAL];
		}
	}
	else if ([key isEqual:POWER_TOTAL])
	{
		[self willChangeValueForKey:POWER_TOTAL];
		
		NSManagedObject * lastEvent = [[EventManager sharedInstance] lastUpdateForIdentifier:[self identifier] event:@"device_total"];
		
		if (![[lastEvent valueForKey:@"value"] isEqual:[value description]])
		{
			NSString * message = [NSString stringWithFormat:@"Current power usage total: %@ kWh.", [value description]];
			
			[[EventManager sharedInstance] createEvent:@"device_total" source:[self identifier] initiator:[self identifier]
										   description:message value:[value description]];
		}
		
		[super setValue:value forKey:key];
		
		[self didChangeValueForKey:POWER_TOTAL];
	}
	else
		[super setValue:value forKey:key];
}

- (void) setCurrentPower:(NSNumber *) power
{
	[self setValue:power forKey:POWER_LEVEL];
}

- (void) setTotalPower:(NSNumber *) power
{
	[self setValue:power forKey:POWER_TOTAL];
}

- (NSNumber *) level
{
	return [self valueForKey:POWER_LEVEL];
}

- (BOOL) checksStatus
{
	return YES;
}

- (BOOL) canReset
{
	return YES;
}


@end
