//
//  Device.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#include <stdlib.h>

#import "Device.h"

#import "MotionSensor.h"
#import "ApertureSensor.h"
#import "PowerSensor.h"
#import "PowerMeterSensor.h"
#import "Lock.h"
#import "Appliance.h"
#import "Lamp.h"
#import "House.h"
#import "Thermostat.h"
#import "Sprinkler.h"
#import "Chime.h"
#import "House.h"
#import "MobileClient.h"
#import "Camera.h"
#import "Phone.h"
#import "Controller.h"
#import "RokuDVP.h"
#import "Tivo.h"
#import "Ted5000.h"
#import "WeatherUndergroundStation.h"
#import "GarageHawk.h"

#import "DeviceManager.h"
#import "ConsoleManager.h"
#import "EventManager.h"

#import "Shion.h"

#import <Shion/ASDeviceController.h>
#import <Shion/ASInsteonAddress.h>
#import <Shion/ASX10Address.h>

#define CHECK_STATUS @"check_status"
#define TWOWAY @"twoway"

#define ARMED @"armed"

@implementation Device

- (BOOL) responsive
{
	if (![self checksStatus])
		return YES;
	
	NSDate * lastResponse = [self valueForKey:LAST_RESPONSE];
	NSDate * lastCheck = [self valueForKey:LAST_CHECK];
		
	if (lastCheck != nil && lastResponse != nil)
	{
		if (fabs([lastResponse timeIntervalSinceDate:lastCheck]) < 120)
			return YES;
	}
	
	return NO;
}

- (void) recordResponse
{
	[self setValue:[NSDate date] forKey:LAST_RESPONSE];
}

- (void) fetchStatus
{
	if ((arc4random() % 5 == 0))
		[self fetchInfo];
	
	if ([self checksStatus] && [self armed])
	{
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_STATUS] forKey:DEVICE_COMMAND];
		
		[[DeviceManager sharedInstance] sendCommand:command];
		
		[self setValue:[NSDate date] forKey:LAST_CHECK];
//		[self removeObjectForKey:LAST_RESPONSE];
	}	
}

- (void) fetchInfo
{
	if ([self checksStatus] && [self armed])
	{
		NSMutableDictionary * command = [NSMutableDictionary dictionary];
		[command setValue:[self device] forKey:DEVICE];
		
		[command setValue:[NSNumber numberWithUnsignedInt:AS_GET_INFO] forKey:DEVICE_COMMAND];
		
		[[DeviceManager sharedInstance] sendCommand:command];

		[self setValue:[NSDate date] forKey:LAST_CHECK];
// 		[self removeObjectForKey:LAST_RESPONSE];
	}	
}

- (ASDevice *) device
{
	return nil;
}

- (void) setDevice:(ASDevice *) device
{
	
}


- (BOOL) checksStatus
{
	NSNumber * checks = [self valueForKey:CHECK_STATUS];
	
	if (checks)
		return [checks boolValue];
	
	NSString * platform = [self platform];
	
	if ([platform isEqual:@"Insteon"])
		[self setChecksStatus:YES];
	else if ([[self valueForKey:TWOWAY] boolValue])
		[self setChecksStatus:YES];
	else
		[self setChecksStatus:NO];

	return [self checksStatus];
}

- (void) setChecksStatus:(BOOL) checkStatus
{
	[self setValue:[NSNumber numberWithBool:checkStatus] forKey:CHECK_STATUS];
}

- (NSString *) identifier
{
	return [self valueForKey:IDENTIFIER];
}

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		CFUUIDRef uuid = CFUUIDCreate(NULL);
		NSString * deviceId = ((NSString *) CFUUIDCreateString(NULL, uuid));
		[self setValue:deviceId forKey:IDENTIFIER];
		
		[deviceId release];

		[self setValue:@"Device" forKey:TYPE];

		[self setValue:@"Unknown Location" forKey:LOCATION];
		
		CFRelease(uuid);
	}
	
	return self;
}

+ (Device *) deviceForType:(NSString *) type
{
	if ([type isEqual:MOTION_SENSOR])
		return [MotionSensor dictionary];
	else if ([type isEqual:APERTURE_SENSOR])
		return [ApertureSensor dictionary];
	else if ([type isEqual:POWER_SENSOR])
		return [PowerSensor dictionary];
	else if ([type isEqual:POWER_METER_SENSOR])
		return [PowerMeterSensor dictionary];
	else if ([type isEqual:LOCK])
		return [Lock dictionary];
	else if ([type isEqual:GARAGE_HAWK])
		return [GarageHawk dictionary];
	else if ([type isEqual:APPLIANCE])
		return [Appliance dictionary];
	else if ([type isEqual:LAMP])
		return [Lamp dictionary];
	else if ([type isEqual:HOUSE])
		return [House dictionary];
	else if ([type isEqual:SPRINKLER])
		return [Sprinkler dictionary];
	else if ([type isEqual:THERMOSTAT])
		return [Thermostat dictionary];
	else if ([type isEqual:CHIME])
		return [Chime dictionary];
	else if ([type isEqual:MOBILE_DEVICE])
		return [MobileClient dictionary];
	else if ([type isEqual:CAMERA])
		return [Camera dictionary];
	else if ([type isEqual:ROKU_DVP])
		return [RokuDVP dictionary];
	else if ([type isEqual:TIVO_DVR])
		return [Tivo dictionary];
	else if ([type isEqual:TED_5000])
		return [Ted5000 dictionary];
	else if ([type isEqual:WU_STATION])
		return [WeatherUndergroundStation dictionary];
	else
	{
		NSRunAlertPanel(@"Debug: Unknown device type", type, @"OK", nil, nil);
		
		return [Device dictionary];
	}
}

+ (Device *) deviceForType:(NSString *) type platform:(NSString *) platform
{
	Device * device = [Device deviceForType:type];
	
	[device setPlatform:platform];

//	if (![platform isEqual:PLATFORM_INSTEON] && ![platform isEqual:PLATFORM_X10])
//		NSRunAlertPanel(@"Debug: Unknown device platform", platform, @"OK", nil, nil);

	[device setName:[NSString stringWithFormat:@"New %@", type]];

	return device;
}

- (NSString *) name
{
	return [self valueForKey:NAME];
}
	
- (void) setName:(NSString *) name
{
	[self setValue:name forKey:NAME];
}

- (NSString *) location
{
	return [self valueForKey:LOCATION];
}

- (void) setLocation:(NSString *) location
{
	[self setValue:location forKey:LOCATION];

	[[ConsoleManager sharedInstance] reloadDevices];
}

- (BOOL) armed
{
	NSNumber * armed = [self valueForKey:ARMED];
	
	if (armed != nil)
		return [armed boolValue];
	
	return YES;
}

- (void) disarm
{
	[self setValue:[NSNumber numberWithBool:NO] forKey:ARMED];
}

- (void) arm
{
	[self setValue:[NSNumber numberWithBool:YES] forKey:ARMED];
}

- (NSString *) address
{
	return [self valueForKey:ADDRESS];
}

- (void) setAddress:(NSString *) address
{
	if (address == nil)
		address = @"";
	
	NSMutableString * mutableAddress = [NSMutableString stringWithString:[address lowercaseString]];
	
	if ([mutableAddress rangeOfString:@"/"].location == NSNotFound && [mutableAddress rangeOfString:@".local"].location == NSNotFound)
		[mutableAddress replaceOccurrencesOfString:@"." withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableAddress length])];
	
	[mutableAddress replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableAddress length])];
	
	[self willChangeValueForKey:ADDRESS];
	
	[self setObject:mutableAddress forKey:ADDRESS];
	
	ASAddress * asAddress = nil;
	
	if ([[self platform] isEqual:@"Insteon"])
	{
		ASInsteonAddress * insteon = [[ASInsteonAddress alloc] init];
		[insteon setAddress:[ASInsteonAddress addressForString:mutableAddress]];

		asAddress = [insteon autorelease];
	}
	else if ([[self platform] isEqual:@"X10"])
	{
		ASX10Address * xTen = [[ASX10Address alloc] init];
		[xTen setAddress:mutableAddress];
		
		asAddress = [xTen autorelease];
	}
	
	ASDevice * device = [self device];
	
	if (device != nil)
		[device setAddress:asAddress];
	
	[self didChangeValueForKey:ADDRESS];
}

- (NSString *) model
{
	return [self valueForKey:MODEL];
}

- (void) setModel:(NSString *) model
{
	[self setValue:model forKey:MODEL];
}

- (NSString *) version
{
	return [self valueForKey:VERSION];
}

- (void) setVersion:(NSString *) version
{
	[self setValue:version forKey:VERSION];
}

- (NSString *) description
{
	return [self valueForKey:DESCRIPTION];
}

- (void) setDescription:(NSString *) description
{
	[self setValue:description forKey:DESCRIPTION];
}

- (NSString *) type
{
	return [self valueForKey:TYPE];
}

- (NSString *) platform
{
	return [self valueForKey:PLATFORM];
}

- (void) setPlatform:(NSString *) platform
{
	if ([platform isEqual:@"Insteon"])
		[self setChecksStatus:YES];
	
	[self setValue:platform forKey:PLATFORM];
}

- (NSData *) data
{
	[self removeObjectForKey:FRAMEWORK_DEVICE];
	
	return [NSArchiver archivedDataWithRootObject:self];
}

+ (Device *) deviceFromData:(NSData *) data
{
	NSDictionary * dataDict = [NSUnarchiver unarchiveObjectWithData:data];
	
	NSString * type = [dataDict valueForKey:TYPE];
	
	if ([type isEqual:@"Appliance"])
		return [Appliance dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Lamp"])
		return [Lamp dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Thermostat"])
		return [Thermostat dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Sprinkler"])
		return [Sprinkler dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Motion Sensor"])
		return [MotionSensor dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Aperture Sensor"])
		return [ApertureSensor dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Power Sensor"])
		return [PowerSensor dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Power Meter Sensor"])
	{
		if ([[dataDict valueForKey:MODEL] isEqual:TED_5000])
			return [Ted5000 dictionaryWithDictionary:dataDict];
		
		return [PowerMeterSensor dictionaryWithDictionary:dataDict];
	}
	else if ([type isEqual:@"Weather Station"])
	{
		if ([[dataDict valueForKey:MODEL] isEqual:WU_STATION])
			return [WeatherUndergroundStation dictionaryWithDictionary:dataDict];
	}
	else if ([type isEqual:@"Lock"])
		return [Lock dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"GarageHawk"])
		return [GarageHawk dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Chime"])
		return [Chime dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"House"])
		return [House dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Mobile Device"])
		return [MobileClient dictionaryWithDictionary:dataDict];
	else if ([type isEqual:@"Camera"])
		return [Camera dictionaryWithDictionary:dataDict];
	else if ([type isEqual:ROKU_DVP])
		return [RokuDVP dictionaryWithDictionary:dataDict];
	else if ([type isEqual:TIVO_DVR])
		return [Tivo dictionaryWithDictionary:dataDict];

	return [Device dictionaryWithDictionary:dataDict];
}

- (void) addEvent:(NSManagedObject *) event
{
	// TODO
}

- (NSArray *) events
{
	return [[EventManager sharedInstance] eventsForIdentifier:[self identifier]];
}

- (id) valueForKey:(NSString *) key
{
	if ([key isEqual:LAST_UPDATE])
	{
		NSString * identifier = [self identifier];

		if ([self isKindOfClass:[Controller class]])
			identifier = @"Controller";
		else if ([self isKindOfClass:[Phone class]])
			identifier = @"Phone";
		
		NSManagedObject * event = [[EventManager sharedInstance] lastUpdateForIdentifier:identifier event:nil];
		
		if (event)
			return [event valueForKey:@"date"];
		else
			return nil;
	}
	else if ([key isEqual:@"state"])
		return [self snapshotDescription:[self snapshotValues]];
	else if ([key isEqual:@"responsiveColor"])
	{
		if ([self responsive])
			return [NSColor blackColor];
		
		return [NSColor colorWithDeviceRed:0.561 green:0.067 blue:0.031 alpha:1.0];
	}
	else
		return [super valueForKey:key];
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	[self willChangeValueForKey:LAST_UPDATE];
	[self willChangeValueForKey:@"responsiveColor"];

	[super setValue:value forKey:key];
	
	if ([key isEqual:TWOWAY])
		[self removeObjectForKey:CHECK_STATUS];
	if ([key isEqual:ADDRESS])
		[self setAddress:value];
	
	[self didChangeValueForKey:@"responsiveColor"];
	[self didChangeValueForKey:LAST_UPDATE];
}

- (NSDictionary *) snapshotValues
{
	return [NSDictionary dictionary];
}

- (Device *) canonicalDevice
{
	Device * device = [Device deviceForType:[self type]];
	
	[device disarm];
	
	NSEnumerator * keyIter = [[self allKeys] objectEnumerator];
	NSString * key = nil;
	while (key = [keyIter nextObject])
	{
		id value = [self valueForKey:key];
		
		if ([value isKindOfClass:[NSString class]])
			[device setValue:value forKey:key];
		else if ([value isKindOfClass:[NSNumber class]])
			[device setValue:value forKey:key];
	}

	[device arm];
	
	[device removeObjectForKey:FRAMEWORK_DEVICE];
			 
	return device;
}

- (NSString *) snapshotDescription:(NSDictionary *) snapValues
{
	return @"Unknown state for snapshot.";
}

- (NSScriptObjectSpecifier *) objectSpecifier
{
	NSScriptObjectSpecifier * devicesSpecifier = [NSApp objectSpecifier];

	return [[[NSNameSpecifier alloc] initWithContainerClassDescription:[devicesSpecifier containerClassDescription]
												   containerSpecifier:devicesSpecifier
																  key:@"devices"
																 name:[self name]] autorelease];
	
//	return [[NSIndexSpecifier alloc] initWithContainerClassDescription:[devicesSpecifier containerClassDescription]
//													containerSpecifier:devicesSpecifier 
//																   key:@"devices" 
//																 index:[[devices devices] indexOfObject:self]];
}

- (NSString *) state
{
	return @"Unknown";
}

@end
