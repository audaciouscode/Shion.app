//
//  ASDeviceController.m
//  Shion Framework
//
//  Created by Chris Karr on 12/9/08.
//  Copyright 2008 Audacious Software. 
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#import "ASDeviceController.h"

#import "ASCommands.h"

#import "ASVirtualAddress.h"
#import "ASVirtualDeviceController.h"
#import "ASContinuousDevice.h"
#import "ASThermostatDevice.h"
#import "ASChimeDevice.h"
#import "ASHouseDevice.h"
#import "ASSprinklerDevice.h"
#import "ASPowerMeterDevice.h"
#import "ASLockDevice.h"
#import "ASGarageHawkDevice.h"

#import "ASInsteonAddress.h"
#import "ASX10Address.h"

#import "ASPowerLinc2414Controller.h"
#import "ASCM15AUSBController.h"
#import "ASPowerLinc1132Controller.h"

@implementation ASDeviceController

+ (ASDeviceController *) controllerForDevice:(ASDevice *) device 
{
	return [ASDeviceController controllerForDevice:device skip:[NSArray array]];
}

+ (ASDeviceController *) controllerForDevice:(ASDevice *) device skip:(NSArray *) skip
{
	ASDeviceController * controller = nil;
	
	ASAddress * address = [device getAddress];
	
	if ([address isMemberOfClass:[ASVirtualAddress class]])
		controller = [[[ASVirtualDeviceController alloc] init] autorelease];
	else if ([address isMemberOfClass:[ASInsteonAddress class]])
		controller = [ASPowerLinc2414Controller findController];
	else if ([address isMemberOfClass:[ASX10Address class]])
	{
		controller = [ASCM15AUSBController findController];

		// if (controller == nil || [skip containsObject:controller])
		// 	controller = [ASPowerLinc2414Controller findController];
		
		return controller;
	}
	
	return controller;
}

- (ASDeviceController *) init
{
	devices = [[NSMutableArray alloc] init];
	commandQueue = [[NSMutableArray alloc] init];
	
	return self;
}

- (void) close
{
	ShionLog (@"implement in subclasses");
}

- (void) dealloc
{
	[devices release];
	[commandQueue release];
	
	[super dealloc];
}

- (NSArray *) devices
{
	return devices;
}

- (void) refresh
{
	ShionLog (@"[ASDeviceController refresh]: Implement in subclasses...");
}

- (void) queueCommand: (ASCommand *) command;
{
	ASDevice * device = [command getDevice];
	ASAddress * deviceAddress = [device getAddress];

	if (device != nil && ![devices containsObject:device])
		[devices addObject:device];

	if ([self acceptsCommand:command])
	{
		if ([command isKindOfClass:[ASStatusCommand class]]) // Only ask status once.
		{
			NSEnumerator * iter = [commandQueue objectEnumerator];
			ASCommand * queuedCommand = nil;
		
			while (queuedCommand = [iter nextObject])
			{
				if ([queuedCommand isMemberOfClass:[command class]])
				{
					ASDevice * queuedDevice = [queuedCommand getDevice];
					ASAddress * queuedAddress = [queuedDevice getAddress];
					
					if ([[queuedAddress getAddress] isEqual:[deviceAddress getAddress]])
					{
						return;
					}
				}
			}

			[commandQueue addObject:command];
		}
		else
		{
			BOOL queued = NO;
			
			for (int i = 0; i < [commandQueue count] && !queued; i++)
			{
				ASCommand * thisCommand = [commandQueue objectAtIndex:i];
				
				if ([thisCommand isKindOfClass:[ASStatusCommand class]])
				{
					[commandQueue insertObject:command atIndex:i];
					
					queued = YES;
				}
			}
			
			if (!queued)
				[commandQueue addObject:command];
		}

		ShionLog (@"Command queued. %d items in queue.", [commandQueue count]);
	}
}

- (BOOL) acceptsCommand: (ASCommand *) command;
{
	// Override in subclasses
	
	return NO;
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind
{
	ASCommand * command = nil;
	
	if (commandKind == AS_STATUS)
		command = [[ASStatusCommand alloc] initWithDevice:device];
	else if (commandKind == AS_GET_INFO)
		command = [[ASGetInfoCommand alloc] initWithDevice:device];
	else if ([device isKindOfClass:[ASChimeDevice class]])
	{
		if (commandKind == AS_CHIME)
			command = [[ASChimeCommand alloc] initWithDevice:device];
	}
	else if ([device isKindOfClass:[ASPowerMeterDevice class]])
	{
		if (commandKind == AS_RESET_POWER_METER)
			command = [[ASResetPowerMeterCommand alloc] initWithDevice:device];
	}
	else if ([device isKindOfClass:[ASLockDevice class]])
	{
		if (commandKind == AS_LOCK)
			command = [[ASLockCommand alloc] initWithDevice:device];
		else if (commandKind == AS_UNLOCK)
			command = [[ASUnlockCommand alloc] initWithDevice:device];
	}
	else if ([device isKindOfClass:[ASToggleDevice class]])
	{
		if (commandKind == AS_ACTIVATE)
			command = [[ASActivateCommand alloc] initWithDevice:device];
		else if (commandKind == AS_DEACTIVATE)
			command = [[ASDeactivateCommand alloc] initWithDevice:device];
		else if (commandKind == AS_GET_RAMP_RATE)
			command = [[ASGetRampRateCommand alloc] initWithDevice:device];
		else if (commandKind == AS_SET_RAMP_RATE)
			command = [[ASSetRampRateCommand alloc] initWithDevice:device];
		else if ([device isKindOfClass:[ASContinuousDevice class]])
		{
			if (commandKind == AS_INCREASE)
				command = [[ASIncreaseCommand alloc] initWithDevice:device];
			else if (commandKind == AS_DECREASE)
				command = [[ASDecreaseCommand alloc] initWithDevice:device];
			else if (commandKind == AS_SET_LEVEL)
				command = [[ASSetLevelCommand alloc] initWithDevice:device];
		}
	}
	else if ([device isKindOfClass:[ASThermostatDevice class]])
	{
		if (commandKind == AS_GET_HVAC_TEMP)
			command = [[ASGetTemperatureCommand alloc] initWithDevice:device];
		else if (commandKind == AS_GET_HVAC_MODE)
			command = [[ASGetThermostatModeCommand alloc] initWithDevice:device];
		else if (commandKind == AS_SET_HVAC_MODE)
			command = [[ASSetThermostatModeCommand alloc] initWithDevice:device];
		else if (commandKind == AS_GET_HVAC_STATE)
			command = [[ASGetThermostatState alloc] initWithDevice:device];
		else if (commandKind == AS_ACTIVATE_HVAC_BROADCAST)
			command = [[ASActivateThermostatStatusBroadcastCommand alloc] initWithDevice:device];
		else if (commandKind == AS_SET_COOL_POINT)
			command = [[ASSetCoolPointCommand alloc] initWithDevice:device];
		else if (commandKind == AS_SET_HEAT_POINT)
			command = [[ASSetHeatPointCommand alloc] initWithDevice:device];
		else if (commandKind == AS_GET_HEAT_POINT)
			command = [[ASGetHeatPointCommand alloc] initWithDevice:device];
		else if (commandKind == AS_GET_COOL_POINT)
			command = [[ASGetCoolPointCommand alloc] initWithDevice:device];
		else if (commandKind == AS_ACTIVATE_FAN)
			command = [[ASActivateFanCommand alloc] initWithDevice:device];
		else if (commandKind == AS_DEACTIVATE_FAN)
			command = [[ASDeactivateFanCommand alloc] initWithDevice:device];
	}
	else if ([device isKindOfClass:[ASHouseDevice class]])
	{
		if (commandKind == AS_ALL_UNITS_OFF)
			command = [[ASAllOffCommand alloc] initWithDevice:device];
		else if (commandKind == AS_ALL_LIGHTS_ON)
			command = [[ASAllLightsOnCommand alloc] initWithDevice:device];
		else if (commandKind == AS_ALL_LIGHTS_OFF)
			command = [[ASAllLightsOffCommand alloc] initWithDevice:device];
	}
	else if ([device isKindOfClass:[ASSprinklerDevice class]])
	{
		if (commandKind == AS_SPRINKLER_ON)
			command = [[ASSprinklerOnCommand alloc] initWithDevice:device];
		else if (commandKind == AS_SPRINKLER_OFF)
			command = [[ASSprinklerOffCommand alloc] initWithDevice:device];
		else if (commandKind == AS_GET_SPRINKLER_VALVE_STATUS)
			command = [[ASSprinklerValveStatusCommand alloc] initWithDevice:device];
		else if (commandKind == AS_GET_SPRINKLER_CONFIGURATION)
			command = [[ASSprinklerFetchConfigurationCommand alloc] initWithDevice:device];
		else if (commandKind == AS_SET_SPRINKLER_DIAGNOSTICS)
			command = [[ASSprinklerSetDiagnosticsConfiguration alloc] initWithDevice:device];
		else if (commandKind == AS_SET_SPRINKLER_PUMP)
			command = [[ASSprinklerSetPumpConfigurationCommand alloc] initWithDevice:device];
		else if (commandKind == AS_SET_SPRINKLER_RAIN)
			command = [[ASSprinklerSetRainSensorConfigurationCommand alloc] initWithDevice:device];
	}
	else if ([device isKindOfClass:[ASGarageHawkDevice class]])
	{
		if (commandKind == AS_GARAGE_CLOSE)
			command = [[ASGarageHawkClose alloc] initWithDevice:device];
	}	
	
	if (command != nil)
		return [command autorelease];
	
	return nil;
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value;
{
	ASCommand * command = [self commandForDevice:device kind:commandKind];
	
	if (command != nil)
	{
		if (commandKind == AS_SET_LEVEL)
			[((ASSetLevelCommand *) command) setLevel:(NSNumber *) value];
		else if (commandKind == AS_SET_RAMP_RATE)
			[((ASSetRampRateCommand *) command) setRate:(NSNumber *) value];
		else if (commandKind == AS_SPRINKLER_ON)
			[((ASSprinklerOnCommand *) command) setUnit:(NSNumber *) value];
		else if (commandKind == AS_SPRINKLER_OFF)
			[((ASSprinklerOffCommand *) command) setUnit:(NSNumber *) value];
		else if (commandKind == AS_SET_SPRINKLER_DIAGNOSTICS)
			[((ASSprinklerSetDiagnosticsConfiguration *) command) setEnabled:[((NSNumber *) value) boolValue]];
		else if (commandKind == AS_SET_SPRINKLER_PUMP)
			[((ASSprinklerSetPumpConfigurationCommand *) command) setEnabled:[((NSNumber *) value) boolValue]];
		else if (commandKind == AS_SET_SPRINKLER_RAIN)
			[((ASSprinklerSetRainSensorConfigurationCommand *) command) setEnabled:[((NSNumber *) value) boolValue]];
	}	

	return command;
}

- (NSArray *) queuedCommands
{
	return commandQueue;
}

/* - (void) executeNextCommand
{
	// implement in subclasses
} */

+ (NSArray *) findControllers
{
	NSMutableSet * controllerSet = [NSMutableSet set];

	// TODO: Fix really ugly syntax below.

	ASPowerLinc2414Controller * plc = [ASPowerLinc2414Controller findController];
	
	if (plc != nil)
		[controllerSet addObject:plc];
	
	ASCM15AUSBController * cm15a = [ASCM15AUSBController findController];
	
	if (cm15a != nil)
		[controllerSet addObject:cm15a];

	ASPowerLinc1132Controller * ghettoPlc = [ASPowerLinc1132Controller findController];
	
	if (ghettoPlc != nil)
		[controllerSet addObject:ghettoPlc];
	
	
	return [controllerSet allObjects];
}

- (NSString *) getName
{
	return name;
}

- (void) setName:(NSString *) new_name
{
	[self willChangeValueForKey:@"name"];
	
	if (name != nil)
		[name release];

	name = [new_name retain];

	[self didChangeValueForKey:@"name"];
}

- (NSString *) getType
{
	return type;
}

- (void) setType:(NSString *) new_type
{
	[self willChangeValueForKey:@"type"];
	
	if (type != nil)
		[type release];
	
	type = [new_type retain];
	
	[self didChangeValueForKey:@"type"];
}

- (ASAddress *) getAddress
{
	return address;
}

- (void) setAddress:(NSString *) new_address
{
	[self willChangeValueForKey:@"address"];
	
	if (address != nil)
		[address release];
	
	address = [new_address retain];
	
	[self didChangeValueForKey:@"address"];
}

/* - (NSString *) description
{
	NSMutableString * desc = [NSMutableString string];
	[desc appendFormat:@"Name: %@\n", [self getName]];
	[desc appendFormat:@"Address: %@\n", [self getAddress]];
	[desc appendFormat:@"Type: %@", [self getType]];
	
	return desc;
} */

- (NSString *) stringForData:(NSData *) data
{
	NSMutableString * string = [NSMutableString string];
	
	unsigned char * bytes = (unsigned char *) [data bytes];
	
	unsigned int i = 0;
	for (i = 0; i < [data length]; i++)
		[string appendString:[NSString stringWithFormat:@"0x%02x ", bytes[i]]];
	
	return string;
}

- (void) resetController
{
	ShionLog(@"Reset Controller (%@): Implement in subclasses...", [self className]);
}

- (void) closeController
{
	ShionLog(@"Close Controller (%@): Implement in subclasses...", [self className]);
}

@end
