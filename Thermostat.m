//
//  Thermostat.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Thermostat.h"

#import "ASDeviceController.h"
#import "ASThermostatDevice.h"

#import "Shion.h"
#import "EventManager.h"
#import "DeviceManager.h"

#define DEVICE_THERMOSTAT_MODE @"thermostat_mode"
#define DEVICE_THERMOSTAT_TEMPERATURE @"thermostat_temperature"
#define DEVICE_THERMOSTAT_FAN @"thermostat_fan"
#define DEVICE_THERMOSTAT_COOL @"thermostat_cool"
#define DEVICE_THERMOSTAT_HEAT @"thermostat_heat"

#define DEVICE_THERMOSTAT_ACTIVE @"thermostat_active"

@implementation Thermostat

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Thermostat" forKey:TYPE];
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
		asDevice = [[ASThermostatDevice alloc] init];
		
		[self setObject:asDevice forKey:FRAMEWORK_DEVICE];
		[asDevice release];
		
		[self setAddress:[self address]];
		
		return [self device];
	}	
}

- (NSString *) mode
{
	return [self valueForKey:DEVICE_THERMOSTAT_MODE];
}
		
- (void) setMode:(NSString *) modeString
{
	if (![[self mode] isEqual:modeString])
		[self setValue:modeString forKey:DEVICE_THERMOSTAT_MODE];
	else if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
			
 		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];

		NSNumber * mode = nil;
		
		if ([modeString isEqual:@"Off"])
			mode = [NSNumber numberWithUnsignedChar:MODE_OFF];
		else if ([modeString isEqual:@"Heat"])
			mode = [NSNumber numberWithUnsignedChar:MODE_HEAT];
		else if ([modeString isEqual:@"Cool"])
			mode = [NSNumber numberWithUnsignedChar:MODE_COOL];
		else if ([modeString isEqual:@"Auto"])
			mode = [NSNumber numberWithUnsignedChar:MODE_AUTO];
		else if ([modeString isEqual:@"Fan"])
			mode = [NSNumber numberWithUnsignedChar:MODE_FAN];
		else if ([modeString isEqual:@"Fan Off"])
			mode = [NSNumber numberWithUnsignedChar:MODE_FAN_OFF];
		else if ([modeString isEqual:@"Program"])
			mode = [NSNumber numberWithUnsignedChar:MODE_PROGRAM];
		else if ([modeString isEqual:@"Program Heat"])
			mode = [NSNumber numberWithUnsignedChar:MODE_PROGRAM_HEAT];
		else if ([modeString isEqual:@"Program Cool"])
			mode = [NSNumber numberWithUnsignedChar:MODE_PROGRAM_COOL];
		
		// [super setValue:mode forKey:DEVICE_THERMOSTAT_MODE]; // WHY? <-
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_SET_HVAC_MODE] forKey:DEVICE_COMMAND];
		
		if (mode != nil)
		{
			[command setValue:mode forKey:COMMAND_VALUE];
			
			[[DeviceManager sharedInstance] sendCommand:command];
		}

		[[EventManager sharedInstance] createEvent:@"device_mode" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user set %@ mode to %@.", [self name], modeString]
											 value:modeString];
			
		[self didChangeValueForKey:LAST_UPDATE];
	}
	else
	{
		[[EventManager sharedInstance] createEvent:@"device_mode" source:[self identifier] initiator:[self identifier]
									   description:[NSString stringWithFormat:@"%@ mode is %@.", [self name], modeString]
											 value:modeString];
	}
}

- (void) setFanState:(BOOL) state
{
	[self willChangeValueForKey:LAST_UPDATE];

	NSMutableDictionary * command = [NSMutableDictionary dictionary];
	[command setValue:[self device] forKey:DEVICE];
	
	if (state)
	{
		[command setValue:[NSNumber numberWithUnsignedInt:AS_ACTIVATE_FAN] forKey:DEVICE_COMMAND];
		
		[[EventManager sharedInstance] createEvent:@"device_fan" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user activated the fan on %@", [self name]]
											 value:@"1"];

		[super setValue:[NSNumber numberWithInt:255] forKey:DEVICE_THERMOSTAT_FAN];
	}
	else
	{
		[command setValue:[NSNumber numberWithUnsignedInt:AS_DEACTIVATE_FAN] forKey:DEVICE_COMMAND];

		[[EventManager sharedInstance] createEvent:@"device_fan" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user deactivated the fan on %@", [self name]]
											 value:@"0"];

		[super setValue:[NSNumber numberWithInt:0] forKey:DEVICE_THERMOSTAT_FAN];
	}

	[[DeviceManager sharedInstance] sendCommand:command];

}

- (BOOL) fanActive
{
	NSNumber * fan = [self valueForKey:DEVICE_THERMOSTAT_FAN];
	
	if (fan)
		return ([fan intValue] > 0);
	
	return NO;
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	[super setValue:value forKey:key];
	
	if ([key isEqual:DEVICE_THERMOSTAT_MODE])
		[self setMode:value];
	else if ([key isEqual:DEVICE_THERMOSTAT_TEMPERATURE])
		[self setTemperature:value];
	else if ([key isEqual:DEVICE_THERMOSTAT_FAN])
		[self setFanState:([value intValue] > 0)];
	else if ([key isEqual:DEVICE_THERMOSTAT_HEAT])
	{
		if ([value isKindOfClass:[NSString class]])
			value = [NSNumber numberWithInt:[value intValue]];
		
		[self setHeatPoint:value];
	}
	else if ([key isEqual:DEVICE_THERMOSTAT_COOL])
	{		
		if ([value isKindOfClass:[NSString class]])
			value = [NSNumber numberWithInt:[value intValue]];

		[self setCoolPoint:value];
	}
}

- (NSNumber *) temperature
{
	return [self valueForKey:DEVICE_THERMOSTAT_TEMPERATURE];
}

- (void) setTemperature:(NSNumber *) temperature
{
	if (![[self temperature] isEqual:temperature])
		[self setValue:temperature forKey:DEVICE_THERMOSTAT_TEMPERATURE];
	
	[[EventManager sharedInstance] createEvent:@"device" source:[self identifier] initiator:[self identifier]
								   description:[NSString stringWithFormat:@"%@ local temperature is %@.", [self name], temperature]
										 value:[temperature description]];
}


- (NSNumber *) heatPoint
{
	return [self valueForKey:DEVICE_THERMOSTAT_HEAT];
}

- (void) setHeatPoint:(NSNumber *) heatPoint
{
	if (![[self heatPoint] isEqual:heatPoint])
		[self setValue:heatPoint forKey:DEVICE_THERMOSTAT_HEAT];

	if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		 
		[command setValue:[self device] forKey:DEVICE];
		 
		[command setValue:[NSNumber numberWithUnsignedInt:AS_SET_HEAT_POINT] forKey:DEVICE_COMMAND];
		[command setValue:heatPoint forKey:COMMAND_VALUE];
		 
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[[EventManager sharedInstance] createEvent:@"device_heat" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user set %@ heat point to %@.", [self name], heatPoint]
											 value:[heatPoint description]];
		
		[self didChangeValueForKey:LAST_UPDATE];
	}
	else 
	{
		[[EventManager sharedInstance] createEvent:@"device_heat" source:[self identifier] initiator:[self identifier]
									   description:[NSString stringWithFormat:@"%@ heat point is %@.", [self name], heatPoint]
											 value:[heatPoint description]];
	}
}

- (void) setRunning:(BOOL) running
{
	NSString * message = [NSString stringWithFormat:@"%@ is running.", [self name]];
	NSString * level = @"255";
	
	if (!running)
	{
		message = [NSString stringWithFormat:@"%@ stopped running.", [self name]];
		level = @"0";
	}

	[[EventManager sharedInstance] createEvent:@"hvac_state" source:[self identifier] initiator:[self identifier]
								   description:message value:level];
	
	[self willChangeValueForKey:DEVICE_THERMOSTAT_ACTIVE];
	[self setValue:[NSNumber numberWithBool:running] forKey:DEVICE_THERMOSTAT_ACTIVE];
	[self didChangeValueForKey:DEVICE_THERMOSTAT_ACTIVE];
	
	[self recordResponse];
}
	 
- (BOOL) isRunning
{
	return [[self valueForKey:DEVICE_THERMOSTAT_ACTIVE] boolValue];
}

- (NSNumber *) coolPoint
{
	return [self valueForKey:DEVICE_THERMOSTAT_COOL];
}

- (void) setCoolPoint:(NSNumber *) coolPoint
{
	if (![[self coolPoint] isEqual:coolPoint])
		[self setValue:coolPoint forKey:DEVICE_THERMOSTAT_COOL];
	
	if ([self armed])
	{
		[self willChangeValueForKey:LAST_UPDATE];
		
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		
		[command setValue:[self device] forKey:DEVICE];

		[command setValue:[NSNumber numberWithUnsignedInt:AS_SET_COOL_POINT] forKey:DEVICE_COMMAND];
		[command setValue:coolPoint forKey:COMMAND_VALUE];
		
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[[EventManager sharedInstance] createEvent:@"device_cool" source:[self identifier] initiator:@"User"
									   description:[NSString stringWithFormat:@"The user set %@ cool point to %@.", [self name], coolPoint]
											 value:[coolPoint description]];
		
		[self didChangeValueForKey:LAST_UPDATE];
	}
	else 
	{
		[[EventManager sharedInstance] createEvent:@"device_cool" source:[self identifier] initiator:[self identifier]
									   description:[NSString stringWithFormat:@"%@ cool point is %@.", [self name], coolPoint]
											 value:[coolPoint description]];
	}
}


- (NSString *) snapshotDescription:(NSDictionary *) snapValues
{
	NSString * modeString = @"Unknown";
	
	if ([snapValues valueForKey:DEVICE_THERMOSTAT_MODE] != nil)
		modeString = [snapValues valueForKey:DEVICE_THERMOSTAT_MODE];

	NSString * fanString = @"Unknown";
	
	if ([snapValues valueForKey:DEVICE_THERMOSTAT_FAN] != nil)
	{
		if ([[snapValues valueForKey:DEVICE_THERMOSTAT_FAN] boolValue])
			fanString = @"On";
		else
			fanString = @"Off";
	}

	NSNumber * coolString = @"Unknown";
	
	if ([snapValues valueForKey:DEVICE_THERMOSTAT_COOL] != nil)
		coolString = [NSString stringWithFormat:@"%@°", [snapValues valueForKey:DEVICE_THERMOSTAT_COOL]];

	NSNumber * heatString = @"Unknown";
	
	if ([snapValues valueForKey:DEVICE_THERMOSTAT_HEAT] != nil)
		heatString = [NSString stringWithFormat:@"%@°", [snapValues valueForKey:DEVICE_THERMOSTAT_HEAT]];
	
	return [NSString stringWithFormat:@"Mode: %@, Cool Pt.: %@, Heat Pt.: %@, Fan: %@", modeString, 
			coolString, heatString, fanString];
}

- (NSDictionary *) snapshotValues
{
	NSMutableDictionary * snapValues = [NSMutableDictionary dictionary];

	if ([self valueForKey:DEVICE_THERMOSTAT_MODE] != nil)
		[snapValues setValue:[self valueForKey:DEVICE_THERMOSTAT_MODE] forKey:DEVICE_THERMOSTAT_MODE];

	if ([self valueForKey:DEVICE_THERMOSTAT_FAN] != nil)
		[snapValues setValue:[self valueForKey:DEVICE_THERMOSTAT_FAN] forKey:DEVICE_THERMOSTAT_FAN];

	if ([self valueForKey:DEVICE_THERMOSTAT_HEAT] != nil)
		[snapValues setValue:[self valueForKey:DEVICE_THERMOSTAT_HEAT] forKey:DEVICE_THERMOSTAT_HEAT];

	if ([self valueForKey:DEVICE_THERMOSTAT_COOL] != nil)
		[snapValues setValue:[self valueForKey:DEVICE_THERMOSTAT_COOL] forKey:DEVICE_THERMOSTAT_COOL];

	return snapValues;
}


@end
