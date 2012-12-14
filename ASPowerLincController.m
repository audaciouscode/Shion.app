//
//  ASPowerLincController.m
//  Shion Framework
//
//  Created by Chris Karr on 2/20/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASPowerLincController.h"

#import "ASCommands.h"
#import "ASThermostatDevice.h"
#import "ASSprinklerDevice.h"
#import "ASContinuousDevice.h"
#import "ASMotionDetector.h"
#import "ASPowerMeterDevice.h"
#import "ASGarageHawkDevice.h"

#import "ASInsteonAddress.h"
#import "ASX10Address.h"
#import "ASInsteonDatabase.h"

#define NEEDS_TRANSMIT @"Needs Transmit"

@implementation ASPowerLincController

- (id) init
{
	if (self = [super init])
	{
		infoDevices = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (BOOL) acceptsCommand: (ASCommand *) command;
{
	if ([command isMemberOfClass:[ASStatusCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASEnableStatusCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDisableStatusCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetInfoCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASActivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDeactivateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetLevelCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetTemperatureCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetThermostatModeCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetThermostatModeCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetThermostatState class]])
		return YES;
	else if ([command isMemberOfClass:[ASActivateThermostatStatusBroadcastCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetCoolPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSetHeatPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetCoolPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASGetHeatPointCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAggregateCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASIncreaseCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDecreaseCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASActivateFanCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASDeactivateFanCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASChimeCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAllOffCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAllLightsOnCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASAllLightsOffCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSprinklerOnCommand class]])
		return YES;
	else if ([command isMemberOfClass:[ASSprinklerOffCommand class]])
		return YES;
	else if ([command isKindOfClass:[ASSprinklerSetConfigurationCommand class]])
		return YES;
	else if ([command isKindOfClass:[ASResetPowerMeterCommand class]])
		return YES;
	else if ([command isKindOfClass:[ASLockCommand class]])
		return YES;
	else if ([command isKindOfClass:[ASUnlockCommand class]])
		return YES;
	else if ([command isKindOfClass:[ASGarageHawkClose class]])
		return YES;
	else if ([command isMemberOfClass:[ASCommand class]])
		return YES;
	
	return NO;
}

- (ASDevice *) deviceWithAddress:(NSData *) addressBytes
{
	NSEnumerator * iter = [devices objectEnumerator];
	ASDevice * device = nil;
	while (device = [iter nextObject])
	{
		ASAddress * deviceAddress = [device getAddress];
		
		if ([deviceAddress isKindOfClass:[ASInsteonAddress class]])
		{
			if ([[((ASInsteonAddress *) deviceAddress) getAddress] isEqualToData:addressBytes])
				return device;
		}
	}
	
	return nil;
}

- (void) processStandardInsteonMessage:(NSData *) message
{
	ShionLog (@"** Processing standard message: %@", [self stringForData:message]);
	
	unsigned char * bytes = (unsigned char *) [message bytes];
	
	BOOL ack = (bytes[6] & 0x20) == 0x20;
	BOOL broadcast = (bytes[6] & 0x80) == 0x80;
	
	NSData * addressBytes = [message subdataWithRange:NSMakeRange(0, 3)];
	ASDevice * device = [self deviceWithAddress:addressBytes];
	
	if (device != nil) // One we know
	{
		if (broadcast) // 0x0b 0x50 0x9f 0x01 0x01 0x27 0x8f 0x01 0x00
		{
			if (bytes[7] == 0x01 || bytes[7] == 0x02) // SB Set Button Broadcast
			{
				NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
				[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
				[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
				
				[userInfo setValue:[ASInsteonDatabase stringForDeviceType:[message subdataWithRange:NSMakeRange(3, 2)]] forKey:DEVICE_MODEL];
				[userInfo setValue:[NSNumber numberWithInt:(0 + bytes[5])] forKey:DEVICE_FIRMWARE];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
			}
			else if (bytes[7] == 0x11 || bytes[7] == 0x13)
			{
				NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
				[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
				
				[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
				[userInfo setObject:[NSNumber numberWithUnsignedChar:bytes[8]] forKey:DEVICE_STATE];
				
				if (bytes[7] == 0x13)
					[userInfo setObject:[NSNumber numberWithUnsignedChar:0x00] forKey:DEVICE_STATE];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
			}
		}
		else if (ack)
		{
			if ([device isKindOfClass:[ASToggleDevice class]])
			{
				if ([infoDevices containsObject:device])
					[infoDevices removeObject:device];
				else
				{
					NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
					[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
					
					[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
					
					if (bytes[7] == 0x13)
					{
						[((ASToggleDevice *) device) setActive:NO];
						
						[userInfo setObject:[NSNumber numberWithUnsignedInt:0] forKey:DEVICE_STATE];
					}
					else
					{
						if ([device isKindOfClass:[ASContinuousDevice class]])
						{
							unsigned int level = 0 + bytes[8];
							[((ASContinuousDevice *) device) setLevel:[NSNumber numberWithUnsignedInt:level]];
						}
						else
						{
							if (bytes[8] > 0x00)
								bytes[8] = 0xff;
						}
						
						if (bytes[8] > 0x00)
							[((ASToggleDevice *) device) setActive:YES];
						else
							[((ASToggleDevice *) device) setActive:NO];
						
						[userInfo setObject:[NSNumber numberWithUnsignedInt:(0 + bytes[8])] forKey:DEVICE_STATE];
					}
					
					[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				}
			}
			else if ([device isKindOfClass:[ASThermostatDevice class]])
			{
				ASThermostatDevice * thermostat = (ASThermostatDevice *) device;
				
				if (bytes[7] == 0x6a && bytes[8] > 0x00)
				{
					NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
					[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
					[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];

					if ([thermostat getMode] == 0x02 && bytes[8] > 10) // Cool
					{
						[thermostat setCoolPoint:[NSNumber numberWithUnsignedChar:(bytes[8] / 2)]];
						[userInfo setObject:[thermostat getCoolPoint] forKey:THERMOSTAT_COOL_POINT];
					}
					else if (bytes[8] > 10)
					{
						[thermostat setHeatPoint:[NSNumber numberWithUnsignedChar:(bytes[8] / 2)]];
						[userInfo setObject:[thermostat getHeatPoint] forKey:THERMOSTAT_HEAT_POINT];
					}

					[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				}
				else if (bytes[7] == 0x6b)
				{
					NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
					[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
					[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
					
					if (lastSubcommand > 0x03 && lastSubcommand < 0x18)
					{
						
					}
					else if (bytes[8] < 0x08)
					{
						[thermostat setMode:bytes[8]];
						[userInfo setObject:[NSNumber numberWithUnsignedInt:(0 + [thermostat getMode])] forKey:THERMOSTAT_MODE];
					}
					else if (bytes[8] != 0xff)
					{
						[thermostat setTemperature:[NSNumber numberWithUnsignedChar:(bytes[8] / 2)]];
						[userInfo setObject:[thermostat getTemperature] forKey:THERMOSTAT_TEMPERATURE];
					}
					
					[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				}
				
				
				/*
				 
				 if ([device isKindOfClass:[ASThermostatDevice class]])
				 {
				 NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
				 [userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
				 
				 [userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
				 
				 ASThermostatDevice * thermostat = (ASThermostatDevice *) device;
				 
				 if (bytes[7] == 0x6a)
				 {
				 if ([thermostat getMode] == MODE_AUTO)
				 {
				 if (setpoints[0] == 0x00)
				 setpoints[0] = bytes[8];
				 else if (setpoints[0] != bytes[8])
				 setpoints[1] = bytes[8];
				 
				 if (setpoints[0] != 0x00 && setpoints[1] != 0x00)
				 {
				 if (setpoints[0] < setpoints[1])
				 {
				 [thermostat setCoolPoint:[NSNumber numberWithUnsignedChar:(setpoints[1] / 2)]];
				 [thermostat setHeatPoint:[NSNumber numberWithUnsignedChar:(setpoints[0] / 2)]];
				 }
				 else
				 {
				 [thermostat setCoolPoint:[NSNumber numberWithUnsignedChar:(setpoints[0] / 2)]];
				 [thermostat setHeatPoint:[NSNumber numberWithUnsignedChar:(setpoints[1] / 2)]];
				 }
				 
				 [userInfo setObject:[thermostat getCoolPoint] forKey:THERMOSTAT_COOL_POINT];
				 [userInfo setObject:[thermostat getHeatPoint] forKey:THERMOSTAT_HEAT_POINT];
				 
				 setpoints[0] = 0;
				 setpoints[1] = 0;
				 
				 [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				 }
				 }
				 else if ([thermostat getMode] == MODE_HEAT)
				 {
				 if (setpoints[0] == 0x00)
				 setpoints[0] = bytes[8];
				 
				 if (setpoints[0] != 0x00)
				 {				
				 [thermostat setHeatPoint:[NSNumber numberWithUnsignedChar:(setpoints[0] / 2)]];
				 [userInfo setObject:[thermostat getHeatPoint] forKey:THERMOSTAT_HEAT_POINT];
				 [userInfo setObject:[NSNumber numberWithUnsignedChar:0xff] forKey:THERMOSTAT_COOL_POINT];
				 
				 [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				 }
				 }
				 else if ([thermostat getMode] == MODE_COOL)
				 {
				 if (setpoints[0] == 0x00)
				 setpoints[0] = bytes[8];
				 
				 if (setpoints[0] != 0x00)
				 {				
				 [thermostat setCoolPoint:[NSNumber numberWithUnsignedChar:(setpoints[0] / 2)]];
				 [userInfo setObject:[thermostat getCoolPoint] forKey:THERMOSTAT_COOL_POINT];
				 [userInfo setObject:[NSNumber numberWithUnsignedChar:0xff] forKey:THERMOSTAT_HEAT_POINT];
				 
				 [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				 }
				 }
				 else if ([thermostat getMode] == MODE_OFF)
				 {
				 [userInfo setObject:[NSNumber numberWithUnsignedChar:0xff] forKey:THERMOSTAT_HEAT_POINT];
				 [userInfo setObject:[NSNumber numberWithUnsignedChar:0xff] forKey:THERMOSTAT_COOL_POINT];
				 
				 [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				 }
				 }
				 else if (bytes[7] == 0x6b)
				 {
				 NSString * property = [thermostat popPropertyFromQueue];
				 
				 if (property == nil)
				 {
				 
				 }
				 }
				 else if ([property isEqualToString:THERMOSTAT_STATE])
				 {
				 [thermostat setState:bytes[8]];
				 [userInfo setObject:[NSNumber numberWithUnsignedInt:(0 + [thermostat getState])] forKey:THERMOSTAT_STATE];
				 }
				 
				 [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				 }
				 else if (bytes[7] == 0x6c)
				 {
				 [thermostat setCoolPoint:[NSNumber numberWithUnsignedChar:(bytes[8] / 2)]];
				 [userInfo setObject:[thermostat getCoolPoint] forKey:THERMOSTAT_COOL_POINT];
				 
				 [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				 }
				 else if (bytes[7] == 0x6d)
				 {
				 [thermostat setHeatPoint:[NSNumber numberWithUnsignedChar:(bytes[8] / 2)]];
				 [userInfo setObject:[thermostat getHeatPoint] forKey:THERMOSTAT_HEAT_POINT];
				 
				 [[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				 }
				 else
				 {
				 // NSLog(@"0x%2x unknown", bytes[7]);
				 }
				 }
				 */				 
				
			}
			else if ([device isKindOfClass:[ASSprinklerDevice class]])
			{
				if (bytes[7] == 0x40)
				{
					NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
					[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
					[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
					
					unsigned char valve = bytes[8] & 0x07;
					BOOL running = ((bytes[8] & 0x80) == 0x80);
					BOOL pumpEnabled = ((bytes[8] & 0x20) == 0x20);
					
					if (running)
						[userInfo setValue:[NSNumber numberWithUnsignedChar:valve] forKey:DEVICE_STATE];
					else
						[userInfo setValue:[NSNumber numberWithUnsignedChar:0x08] forKey:DEVICE_STATE];
					
					[userInfo setValue:[NSNumber numberWithBool:pumpEnabled] forKey:SPRINKLER_PUMP_ENABLED];
					
					[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				}
			}
			else if ([device isKindOfClass:[ASPowerMeterDevice class]])
			{
				if (bytes[7] == 0x82)
				{
					
				}
				else
					ShionLog (@"** Unknown message for power meter device %@: %@", device, [self stringForData:message]);
			}
			else 
			{
				ShionLog (@"** Unknown message for device %@: %@", device, [self stringForData:addressBytes]);
			}
		}
		else
		{
			if ([infoDevices containsObject:device])
				[infoDevices removeObject:device];

			if ([device isKindOfClass:[ASToggleDevice class]])
			{
				NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
				[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
				
				[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
				
				if (bytes[7] == 0x11)
				{
					[((ASToggleDevice *) device) setActive:YES];
					
					[userInfo setObject:[NSNumber numberWithUnsignedInt:0xff] forKey:DEVICE_STATE];
				}
				else if (bytes[7] == 0x13)
				{
					[((ASToggleDevice *) device) setActive:NO];
					
					[userInfo setObject:[NSNumber numberWithUnsignedInt:0] forKey:DEVICE_STATE];
				}
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
			}
			else if ([device isKindOfClass:[ASMotionDetector class]])
			{
				NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
				[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
				
				[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
				
				if (bytes[7] == 0x11)
					[userInfo setObject:[NSNumber numberWithUnsignedInt:0xff] forKey:DEVICE_STATE];
				else if (bytes[7] == 0x13)
					[userInfo setObject:[NSNumber numberWithUnsignedInt:0] forKey:DEVICE_STATE];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
			}
			else if ([device isKindOfClass:[ASThermostatDevice class]])
			{
				ASThermostatDevice * thermostat = (ASThermostatDevice *) device;
				
				if (bytes[7] == 0x6a)
				{
					NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
					[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
					[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
					
					[thermostat setCoolPoint:[NSNumber numberWithUnsignedChar:(bytes[8] / 2)]];
					[userInfo setObject:[thermostat getCoolPoint] forKey:THERMOSTAT_COOL_POINT];
					
					[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				}
			}
			else if ([device isKindOfClass:[ASSprinklerDevice class]])
			{
				if (bytes[7] == 0x27)
				{
					NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
					[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
					
					[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
					
					if ((bytes[8] & 0x80) == 0x80)
						[userInfo setValue:[NSNumber numberWithUnsignedChar:(bytes[8] & 0x07)] forKey:DEVICE_STATE];
					else
						[userInfo setValue:[NSNumber numberWithUnsignedChar:0x08] forKey:DEVICE_STATE];
					
					BOOL inDiagnostics = ((bytes[3] & 0x01) == 0x01);
					BOOL isRaining = ((bytes[3] & 0x02) == 0x04);
					BOOL valvesDisabled = ((bytes[3] & 0x08) == 0x08);
					BOOL rainEnabled = ((bytes[3] & 0x10) == 0x10);
					BOOL meterBroadcast = ((bytes[3] & 0x20) == 0x20);
					BOOL valveBroadcast = ((bytes[3] & 0x40) == 0x40);
					BOOL pumpEnabled = ((bytes[3] & 0x80) == 0x80);
					
					[userInfo setValue:[NSNumber numberWithBool:inDiagnostics] forKey:SPRINKLER_DIAGNOSTICS];
					[userInfo setValue:[NSNumber numberWithBool:isRaining] forKey:SPRINKLER_RAINING];
					[userInfo setValue:[NSNumber numberWithBool:valvesDisabled] forKey:SPRINKLER_VALVES_DISABLED];
					[userInfo setValue:[NSNumber numberWithBool:rainEnabled] forKey:SPRINKLER_RAIN_ENABLED];
					[userInfo setValue:[NSNumber numberWithBool:meterBroadcast] forKey:SPRINKLER_METER_BROADCAST];
					[userInfo setValue:[NSNumber numberWithBool:valveBroadcast] forKey:SPRINKLER_VALVES_BROADCAST];
					[userInfo setValue:[NSNumber numberWithBool:pumpEnabled] forKey:SPRINKLER_PUMP_ENABLED];
					
					[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
				}
			}
			else if ([device isKindOfClass:[ASGarageHawkDevice class]])
			{
				if (bytes[7] == 0x5a)
				{
					NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
					[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
					[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
					
					if (bytes[8] == 0x0b)
						[userInfo setObject:[NSNumber numberWithUnsignedInt:0] forKey:DEVICE_STATE];
					else if (bytes[8] == 0x0c)
						[userInfo setObject:[NSNumber numberWithUnsignedInt:128] forKey:DEVICE_STATE];
					else if (bytes[8] == 0x0d)
						[userInfo setObject:[NSNumber numberWithUnsignedInt:255] forKey:DEVICE_STATE];
					else if (bytes[8] == 0x0e)
						[userInfo setObject:[NSNumber numberWithUnsignedInt:64] forKey:DEVICE_STATE];
					else if (bytes[8] == 0x0f)
						[userInfo setObject:[NSNumber numberWithUnsignedInt:192] forKey:DEVICE_STATE];
					
					if ([userInfo valueForKey:DEVICE_STATE] != nil)
						[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
					else
						ShionLog (@"** Unknown message for GarageHawk device %@: %@", device, [self stringForData:message]);
				}
				else
					ShionLog (@"** Unknown message for GarageHawk device %@: %@", device, [self stringForData:message]);
			}
		}
	}
	else
	{
		if (bytes[7] == 0x11) // Sensor On
		{
			NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
			[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
			[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
			[userInfo setObject:[NSNumber numberWithUnsignedInt:255] forKey:DEVICE_STATE];
			[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
		}
		else if (bytes[7] == 0x13) // Sensor Off
		{
			NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
			[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
			[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
			[userInfo setObject:[NSNumber numberWithUnsignedInt:0] forKey:DEVICE_STATE];
			[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
		}
		else
			ShionLog (@"** Unable to locate device with address: %@", [self stringForData:addressBytes]);
	}
}

- (void) processExtendedInsteonMessage:(NSData *) message
{
	NSData * addressBytes = [message subdataWithRange:NSMakeRange(0, 3)];
	ASDevice * device = [self deviceWithAddress:addressBytes];

	if (device != nil)
	{
		if ([device isKindOfClass:[ASPowerMeterDevice class]])
		{
			// iMeter Solo: http://www.insteon.net/pdf/2423A1_iMeter_Solo_20110211.pdf
			// 0x18 0xf5 0x7a 0x0f 0xde 0x8b 0x1b 0x82 0x00 0x00 0x00 0x01 0x07 0x00 0x91 [0x00 0x01] 0x00 0x00 0x23 0x54 0xf6 0xa1
		
			unsigned char * bytes = (unsigned char *) [message bytes];
			
			if ([message length] >= 23)
			{
				unsigned int truePower = (bytes[15] * 256) + bytes[16];
				unsigned long accumulated = bytes[17];
				accumulated = (accumulated << 8) + bytes[18];
				accumulated = (accumulated << 8) + bytes[19];
				accumulated = (accumulated << 8) + bytes[20];
				
				float total = accumulated * 65535.0 / (1000 * 60 * 60 * 60);
				
//				(bytes[17] * 256*256*256) + (bytes[18] * 256*256) + (bytes[19] * 256) + bytes[20];

				NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
				[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
				[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
				
				[userInfo setObject:[NSNumber numberWithUnsignedInt:truePower] forKey:CURRENT_POWER];
				[userInfo setObject:[NSString stringWithFormat:@"%0.3f", total] forKey:ACCUMULATED_POWER];
				
				[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
			}
			
			return;
		}
	}
	
	ShionLog (@"** TODO processing extended message: %@", [self stringForData:message]);
}

- (NSData *) insteonDataForDevice:(ASDevice *)device command:(ASCommand *) command value:(NSObject *) value
{
	ASAddress * deviceAddress = [device getAddress];
	
	NSMutableData * commandData = [NSMutableData data];
	
	if ([command isMemberOfClass:[ASSetLevelCommand class]])
	{	
		unsigned int level = [((NSNumber *) value) unsignedCharValue];
		
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x11, level};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASSetThermostatModeCommand class]])
	{
		unsigned char mode = [((NSNumber *) value) unsignedCharValue];
		
		if (mode == MODE_OFF)
			mode = 0x09;
		else if (mode == MODE_HEAT)
			mode = 0x04;
		else if (mode == MODE_COOL)
			mode = 0x05;
		else if (mode == MODE_AUTO)
			mode = 0x06;
		else if (mode == MODE_FAN)
			mode = 0x07;
		else if (mode == MODE_FAN_OFF)
			mode = 0x08;
		else if (mode == MODE_PROGRAM)
			mode = 0x0c;
		else if (mode == MODE_PROGRAM_HEAT)
			mode = 0x0a;
		else if (mode == MODE_PROGRAM_COOL)
			mode = 0x0c;
		else
			mode = 0x00;
		
		if (mode != 0x00)
		{
			unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6b, mode};
			
			[commandData appendBytes:bytes length:6];
		}
	}	
	else if ([command isMemberOfClass:[ASSetCoolPointCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6c, ([((NSNumber *) value) unsignedCharValue] * 2)};
		
		[commandData appendBytes:bytes length:6];
	}	
	else if ([command isMemberOfClass:[ASSetHeatPointCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6d, ([((NSNumber *) value) unsignedCharValue] * 2)};
		
		[commandData appendBytes:bytes length:6];
	}	
	else if ([command isMemberOfClass:[ASSprinklerOnCommand class]])
	{	
		unsigned char unit = [((NSNumber *) value) unsignedCharValue];
		
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x40, unit};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASSprinklerOffCommand class]])
	{	
		unsigned char unit = [((NSNumber *) value) unsignedCharValue];
		
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x41, unit};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isKindOfClass:[ASSprinklerSetConfigurationCommand class]])
	{
		ASSprinklerSetConfigurationCommand * sprinklerCommand = (ASSprinklerSetConfigurationCommand *) command;
		
		BOOL enabled = [sprinklerCommand enabled];
		
		unsigned char commandByte = 0x02;
		
		if ([sprinklerCommand isMemberOfClass:[ASSprinklerSetDiagnosticsConfiguration class]])
		{
			if (enabled)
				commandByte = 0xFE;
			else
				commandByte = 0xFF;
		}
		else if ([sprinklerCommand isMemberOfClass:[ASSprinklerSetPumpConfigurationCommand class]])
		{
			if (enabled)
				commandByte = 0x07;
			else
				commandByte = 0x08;
		}
		else if ([sprinklerCommand isMemberOfClass:[ASSprinklerSetRainSensorConfigurationCommand class]])
		{
			if (enabled)
				commandByte = 0x0b;
			else
				commandByte = 0x0c;
		}
		
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x44, commandByte};
		
		[commandData appendBytes:bytes length:6];
	}
	
	if ([commandData length] == 0)
		[commandData appendData:[self insteonDataForDevice:device command:nil]];
	
	NSData * addressBytes = [((ASInsteonAddress *) deviceAddress) getAddress];
	
	[commandData replaceBytesInRange:NSMakeRange (0, [addressBytes length]) withBytes:[addressBytes bytes]];
	
	return commandData;
}

- (NSData *) insteonDataForDevice:(ASDevice *)device command:(ASCommand *) command
{
	NSMutableData * commandData = [NSMutableData data];
	
	if ([command isMemberOfClass:[ASStatusCommand class]])
	{
		if ([device isKindOfClass:[ASToggleDevice class]])
		{
			unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x19, 0x00};
			
			[commandData appendBytes:bytes length:6];
		}
		else if ([device isKindOfClass:[ASMotionDetector class]])
		{
			unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x10, 0x00};
			
			[commandData appendBytes:bytes length:6];
		}
		else if ([device isKindOfClass:[ASPowerMeterDevice class]])
		{
			unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x82, 0x00};
			
			[commandData appendBytes:bytes length:6];
		}
		else if ([device isKindOfClass:[ASGarageHawkDevice class]])
		{
			unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x5a, 0x0a};
			
			[commandData appendBytes:bytes length:6];
		}
	}
	else if ([command isMemberOfClass:[ASGetInfoCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x10, 0x00};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASActivateCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x11, 0xFF};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASDeactivateCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x13, 0x00};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASGetThermostatState class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6b, 0x0d};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASGetTemperatureCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6b, 0x03};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASGetThermostatModeCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6b, 0x02};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASGetHeatPointCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6a, 0xa1};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASGetCoolPointCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6a, 0xa0};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASActivateFanCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6b, 0x07};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASDeactivateFanCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x6b, 0x08};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASSprinklerValveStatusCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x44, 0x09};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASSprinklerFetchConfigurationCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0xfb, 0x00};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASResetPowerMeterCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x80, 0x00};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASLockCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x11, 0xFF};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASUnlockCommand class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x11, 0x00};
		
		[commandData appendBytes:bytes length:6];
	}
	else if ([command isMemberOfClass:[ASGarageHawkClose class]])
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x5a, 0x11};
		
		[commandData appendBytes:bytes length:6];
	}
	
	if ([commandData length] == 0)
	{
		unsigned char bytes[] = {0x00,0x00,0x00, 0x0F,0x03, 0x02};
		
		[commandData appendBytes:bytes length:6];
	}

	ASAddress * deviceAddress = [device getAddress];
	NSData * addressBytes = [((ASInsteonAddress *) deviceAddress) getAddress];
	
	[commandData replaceBytesInRange:NSMakeRange (0, [addressBytes length]) withBytes:[addressBytes bytes]];
	
	return commandData;
}

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value
{
	if (commandKind == AS_SET_COOL_POINT)
	{
		ASSetCoolPointCommand * command = [[ASSetCoolPointCommand alloc] init];
		
		return [command autorelease];
	}
	else if (commandKind == AS_SET_HEAT_POINT)
	{
		ASSetHeatPointCommand * command = [[ASSetHeatPointCommand alloc] init];
		
		return [command autorelease];
	}
	else if (commandKind == AS_SET_HVAC_MODE)
	{
		ASSetThermostatModeCommand * command = [[ASSetThermostatModeCommand alloc] init];
		
		return [command autorelease];
	}
	
	return [super commandForDevice:device kind:commandKind value:value];;
}

- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind
{
	ASCommand * command = [super commandForDevice:device kind:commandKind];
	
	ASAddress * deviceAddress = [device getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASInsteonAddress class]])
	{
		if ([command isMemberOfClass:[ASStatusCommand class]])
		{
			if ([device isMemberOfClass:[ASThermostatDevice class]])
			{
				ASAggregateCommand * commandList = [[ASAggregateCommand alloc] init];
				
				[commandList addCommand:[self commandForDevice:device kind:AS_GET_HVAC_STATE]];
				[commandList addCommand:[self commandForDevice:device kind:AS_GET_HVAC_MODE]];
				[commandList addCommand:[self commandForDevice:device kind:AS_GET_HVAC_TEMP]];
				[commandList addCommand:[self commandForDevice:device kind:AS_GET_HEAT_POINT]];
//				[commandList addCommand:[self commandForDevice:device kind:AS_GET_COOL_POINT]];
				
				[commandList setDevice:device];
				command = [commandList autorelease];
 			}
			else if ([device isKindOfClass:[ASSprinklerDevice class]])
			{
				ASAggregateCommand * commandList = [[ASAggregateCommand alloc] init];
				
				[commandList setDevice:device];
				
				ASCommand * valveStatus = [self commandForDevice:device kind:AS_GET_SPRINKLER_VALVE_STATUS];
				
				if (valveStatus != nil)
					[commandList addCommand:valveStatus];
				
				ASCommand * configStatus = [self commandForDevice:device kind:AS_GET_SPRINKLER_CONFIGURATION];
				
				if (configStatus != nil)
					[commandList addCommand:configStatus];
				
				[commandList setDevice:device];
				command = [commandList autorelease];
			}
		}
	}		
	
	return command;
}

- (void) setControllerVersion:(NSNumber *) version
{
	if (address != nil)
	{
		unsigned char * bytes = (unsigned char *) [[address getAddress] bytes];
		
		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setValue:STATUS_UPDATE forKey:COMMAND_TYPE];
		[userInfo setValue:[NSString stringWithFormat:@"%02x%02x%02x", bytes[0], bytes[1], bytes[2], nil] forKey:DEVICE_ADDRESS];
		[userInfo setValue:CONTROLLER_DEVICE forKey:DEVICE_TYPE];
		[userInfo setValue:[self getType] forKey:DEVICE_MODEL];
		[userInfo setValue:[self getName] forKey:DEVICE_NAME];
		[userInfo setValue:version forKey:DEVICE_FIRMWARE];
	
		[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
	}
}

- (void) setControllerAddress:(NSData *) addressData
{
	if (address == nil)
	{
		address = [[ASInsteonAddress alloc] init];
		[((ASInsteonAddress *) address) setAddress:addressData];
	}
}


@end
