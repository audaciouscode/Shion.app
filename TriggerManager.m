//
//  TriggerManager.m
//  Shion
//
//  Created by Chris Karr on 5/12/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "TriggerManager.h"

#import "ASDevice.h"
#import "ASDeviceController.h"
#import "ASThermostatDevice.h"
#import "ASSerialPortModemDevice.h"
#import "ASX10Address.h"

#import "DeviceManager.h"
#import "PreferencesManager.h"

#import "MotionSensor.h"
#import "ApertureSensor.h"
#import "Thermostat.h"
#import "Phone.h"

#import "WeatherUndergroundStation.h"

#import "SolarEventManager.h"

@implementation TriggerManager

static TriggerManager * sharedInstance = nil;

- (NSString *) triggerStorageFolder 
{
	NSString * applicationSupportFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder (kUserDomain, kApplicationSupportFolderType, kCreateFolder, &foundRef);
	
	if (err != noErr) 
	{
		return nil;
	}
	else 
	{
		unsigned char path[1024];
		FSRefMakePath (&foundRef, path, sizeof(path));
		applicationSupportFolder = [NSString stringWithUTF8String:(char *) path];
		applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:@"Shion"];
	}
	
	BOOL isDir;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:applicationSupportFolder isDirectory:&isDir])
		[[NSFileManager defaultManager] createDirectoryAtPath:applicationSupportFolder attributes:[NSDictionary dictionary]];
	
	return applicationSupportFolder;
}

- (void) loadTriggers
{
	if ([triggers count] > 0)
		[triggers removeAllObjects];
	
	NSString * storageFolder = [self triggerStorageFolder];
	
	NSDirectoryEnumerator * fileIter = [[NSFileManager defaultManager] enumeratorAtPath:storageFolder];
	NSString * file = nil;
	while (file = [fileIter nextObject]) 
	{
		if ([[file pathExtension] isEqualToString:@"trigger"]) 
		{
			NSData * data = [NSData dataWithContentsOfFile:[storageFolder stringByAppendingPathComponent:file]];
			
			if (data)
			{
				Trigger * trigger = [Trigger triggerFromData:data];
				
				[triggers addObject:trigger];
			}
		}
	}
}

- (NSArray *) triggers
{
	return [NSArray arrayWithArray:triggers];
}

- (void) removeTrigger:(Trigger *) trigger
{
	int choice = NSRunAlertPanel(@"Delete trigger?", [NSString stringWithFormat:@"Are you sure that you wish to remove %@?", [trigger name]], @"No", @"Yes", nil);
	
	if (choice == 0)
	{
		NSString * trigsFolder = [self triggerStorageFolder];
		
		NSString * filename = [NSString stringWithFormat:@"%@.trigger", [trigger identifier]];
		NSString * triggerPath = [trigsFolder stringByAppendingPathComponent:filename];
		
		// TODO: Add 10.4 & 10.5+ specific handling code here...
		
		[[NSFileManager defaultManager] removeFileAtPath:triggerPath handler:nil];
		
		[triggers removeObject:trigger];
	}
}

- (Trigger *) createTrigger:(NSString *) triggerType
{
	Trigger * trigger = [Trigger triggerForType:triggerType];
	
	[triggers addObject:trigger];
	
	return trigger;
}

- (id) init
{
	if (self = [super init])
	{
		triggers = [[NSMutableArray alloc] init];
		state = [[NSMutableDictionary alloc] init];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUpdate:) name:DEVICE_UPDATE_NOTIFICATION object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceUpdate:) name:X10_COMMAND_NOTIFICATION object:nil];

		[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
		
		heartbeat  = [[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(beat:) userInfo:nil repeats:YES] retain];

		[self loadTriggers];
	}
	
	return self;
}

+ (TriggerManager *) sharedInstance
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            [[self alloc] init]; // assignment not done here
		}
    }
    return sharedInstance;
}

+ (id) allocWithZone:(NSZone *) zone
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
	
    return nil; //on subsequent allocation attempts return nil
}

- (id) copyWithZone:(NSZone *) zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (unsigned) retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void) release
{
    //do nothing
}

- (id) autorelease
{
    return self;
}

- (void) saveTriggers
{
	NSString * trigsFolder = [self triggerStorageFolder];
	
	NSEnumerator * trigIter = [triggers objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [trigIter nextObject])
	{
		if ([trigger isDirty])
		{
			NSData * data = [trigger data];
		
			if (data)
			{
				NSString * filename = [NSString stringWithFormat:@"%@.trigger", [trigger identifier]];
				NSString * trigPath = [trigsFolder stringByAppendingPathComponent:filename];
			
				[data writeToFile:trigPath atomically:YES];
			}
		}
	}
}

- (void) beat:(NSTimer *) theTimer
{
	NSEnumerator * iter = [triggers objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [iter nextObject])
	{
		NSDate * now = [NSDate date];
		
		if ([[trigger valueForKey:@"trigger_type"] isEqual:DATE_TRIGGER])
		{
			NSDateFormatter * hourAndMinute = [[NSDateFormatter alloc] init];
			[hourAndMinute setDateFormat:@"HH:mm"];

			if ([[hourAndMinute stringFromDate:now] isEqual:[hourAndMinute stringFromDate:[trigger valueForKey:@"date_time"]]])
			{
				NSDateComponents * comps = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:now];
				
				int day = [comps weekday];
				
				if (day == 1 && [[trigger valueForKey:@"date_sunday"] boolValue])
					[trigger fire];
				else if (day == 2 && [[trigger valueForKey:@"date_monday"] boolValue])
					[trigger fire];
				else if (day == 3 && [[trigger valueForKey:@"date_tuesday"] boolValue])
					[trigger fire];
				else if (day == 4 && [[trigger valueForKey:@"date_wednesday"] boolValue])
					[trigger fire];
				else if (day == 5 && [[trigger valueForKey:@"date_thursday"] boolValue])
					[trigger fire];
				else if (day == 6 && [[trigger valueForKey:@"date_friday"] boolValue])
					[trigger fire];
				else if (day == 7 && [[trigger valueForKey:@"date_saturday"] boolValue])
					[trigger fire];
			}
			
			[hourAndMinute release];
		}
		else if ([[trigger valueForKey:@"trigger_type"] isEqual:SOLAR_TRIGGER])
		{
			int sunrise = [SolarEventManager sunrise];
			int sunset = [SolarEventManager sunset];

			NSCalendarDate * now = [NSCalendarDate date];
			unsigned int nowMinutes = ([now hourOfDay] * 60) + [now minuteOfHour];
			
			if ([trigger valueForKey:@"sunrise_minutes"] != nil)
			{
				unsigned int minuteOffset = [[trigger valueForKey:@"sunrise_minutes"] unsignedIntValue];
				
				if ([[trigger valueForKey:@"sunrise_before_after"] isEqual:@"before"])
				{
					sunrise = sunrise - minuteOffset;
					sunset = sunset - minuteOffset;
				}
				else if ([[trigger valueForKey:@"sunrise_before_after"] isEqual:@"after"])
				{
					sunrise = sunrise + minuteOffset;
					sunset = sunset + minuteOffset;
				}
			}
			
			if ([[trigger valueForKey:@"sunrise_or_sunset"] isEqual:@"Sunset"] && sunset == nowMinutes)
				[trigger fire];
			else if ([[trigger valueForKey:@"sunrise_or_sunset"] isEqual:@"Sunrise"] && sunrise == nowMinutes)
				[trigger fire];
		}
	}
}

- (void) deviceUpdate:(NSNotification *) theNote
{
	NSMutableDictionary * userInfo = [NSMutableDictionary dictionaryWithDictionary:[theNote userInfo]];
	
	if ([userInfo valueForKey:X10_ADDRESS] != nil)
	{
		NSString * address = [[userInfo valueForKey:X10_ADDRESS] lowercaseString];
		NSString * command = [userInfo valueForKey:X10_COMMAND];
		
		NSEnumerator * iter = [triggers objectEnumerator];
		Trigger * trigger = nil;
		while (trigger = [iter nextObject])
		{
			if ([[trigger valueForKey:@"trigger_type"] isEqual:X10_TRIGGER] && [trigger valueForKey:@"xten_address"] != nil)
			{
				NSMutableString * triggerAddress = [NSMutableString stringWithString:[[trigger valueForKey:@"xten_address"] lowercaseString]];
				[triggerAddress replaceOccurrencesOfString:@" " withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [triggerAddress length])];
				
				if ([address isEqualToString:triggerAddress])
				{
					if ([[trigger valueForKey:@"xten_on"] boolValue] && [command rangeOfString:X10_ON].location != NSNotFound)
						[trigger fire];
					else if ([[trigger valueForKey:@"xten_off"] boolValue] && [command rangeOfString:X10_OFF].location != NSNotFound)
						[trigger fire];
					else if ([[trigger valueForKey:@"xten_brighten"] boolValue] && [command rangeOfString:X10_BRIGHT].location != NSNotFound)
						[trigger fire];
					else if ([[trigger valueForKey:@"xten_dim"] boolValue] && [command rangeOfString:X10_DIM].location != NSNotFound)
						[trigger fire];
				}
			}
		}
	}
	
	NSString * cmdAddress = [[userInfo valueForKey:DEVICE_ADDRESS] lowercaseString];

	NSEnumerator * iter = [triggers objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [iter nextObject])
	{
		NSEnumerator * iter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		Device * device = nil;
		while (device = [iter nextObject])
		{
			NSString * address = [[device address] lowercaseString];
			
			if ([cmdAddress isEqual:address])
			{
				if ([userInfo valueForKey:DEVICE_STATE] != nil )
				{
					if ([device isKindOfClass:[MotionSensor class]] && [[trigger valueForKey:@"trigger_type"] isEqual:MOTION_TRIGGER] 
						&& [[device name] isEqual:[trigger valueForKey:@"motion_sensor"]])
					{
						NSNumber * level = [userInfo valueForKey:DEVICE_STATE];

						if ([level intValue] == 0 && [[trigger valueForKey:@"motion_cease"] boolValue])
							[trigger fire];
						else if ([level intValue] > 0 && [[trigger valueForKey:@"motion_detect"] boolValue])
							[trigger fire];
					}
					else if ([device isKindOfClass:[ApertureSensor class]] && [[trigger valueForKey:@"trigger_type"] isEqual:APERTURE_TRIGGER] 
						&& [[device name] isEqual:[trigger valueForKey:@"aperture_sensor"]])
					{
						NSNumber * level = [userInfo valueForKey:DEVICE_STATE];
						
						if ([level intValue] == 0 && [[trigger valueForKey:@"aperture_closes"] boolValue])
							[trigger fire];
						else if ([level intValue] > 0 && [[trigger valueForKey:@"aperture_opens"] boolValue])
							[trigger fire];
					}
				}
				
				if ([device isKindOfClass:[Thermostat class]] || [device isKindOfClass:[WeatherUndergroundStation class]])
				{
					NSNumber * temperature = [userInfo valueForKey:THERMOSTAT_TEMPERATURE];
					NSNumber * indoors = [userInfo valueForKey:IS_INDOORS];
					
					if (temperature != nil)
					{
						if ([[trigger valueForKey:@"trigger_type"] isEqual:TEMPERATURE_TRIGGER])
						{
							NSNumber * triggerTemp = [trigger valueForKey:@"temperature_degrees"];
							NSString * location = [trigger valueForKey:@"temperature_location"];
							
							BOOL match = YES;
							
							if (location != nil)
							{
								if (indoors != nil)
								{
									if ([location isEqualToString:@"Indoors"] && [indoors boolValue] == NO)
										match = NO;
									else if ([location isEqualToString:@"Outdoors"] && [indoors boolValue] == YES)
										match = NO;
								}
							}
							
							if (match)
							{
								if (triggerTemp == nil)
									triggerTemp = [NSNumber numberWithInt:100];
								
								int degrees = [temperature intValue];
								int triggerDegrees = [triggerTemp intValue];
								
								BOOL fire = NO;
								
								NSNumber * didFire = [trigger valueForKey:@"did_fire"];
								
								if (didFire == nil)
									didFire = [NSNumber numberWithBool:NO];
								
								if ([[trigger valueForKey:@"temperature_direction"] isEqual:@"falls below"])
								{
									if (degrees > triggerDegrees)
										[trigger setValue:[NSNumber numberWithBool:NO] forKey:@"did_fire"];
									else if (degrees < triggerDegrees && [didFire boolValue] == NO)
										fire = YES;
								}
								else
								{
									if (degrees < triggerDegrees)
										[trigger setValue:[NSNumber numberWithBool:NO] forKey:@"did_fire"];
									else if (degrees > triggerDegrees && [didFire boolValue] == NO)
										fire = YES;
								}
								
								if (fire)
								{
									[trigger fire];
									[trigger setValue:[NSNumber numberWithBool:YES] forKey:@"did_fire"];
								}
							}
						}
					}
				}
				else if ([device isKindOfClass:[Phone class]] && [[trigger valueForKey:@"trigger_type"] isEqual:PHONE_TRIGGER])
				{
					NSString * caller = [userInfo valueForKey:CID_NAME];
					NSString * number = [userInfo valueForKey:CID_NUMBER];
					
					if (caller != nil && number != nil)
					{
						number = [Phone normalizePhoneNumber:number];
						
						ABPerson * person = [Phone findPersonByNumber:number];
						
						if (person != nil)
						{
							NSString * newName = [NSString stringWithFormat:@"%@ %@", [person valueForProperty:kABFirstNameProperty],
												  [person valueForProperty:kABLastNameProperty], nil];
							
							BOOL isCompany = ([[person valueForProperty:kABPersonFlags] intValue] & kABShowAsMask) == kABShowAsCompany;
							
							if (isCompany)
							{
								NSString * orgName = [person valueForProperty:kABOrganizationProperty];
								
								if (orgName != nil)
									newName = orgName;
							}
							
							caller = newName;

							if (caller != nil && number != nil)
							{
								BOOL match = YES;
								
								NSString * callerMatch = [trigger valueForKey:@"phone_caller"];
								if (callerMatch != nil && ![callerMatch isEqualToString:@""])
									match = ([caller rangeOfString:callerMatch].location != NSNotFound);

								NSString * phoneMatch = [trigger valueForKey:@"phone_number"];
								if (phoneMatch != nil && ![phoneMatch isEqualToString:@""])
									match = ([number rangeOfString:phoneMatch].location != NSNotFound) & match;
								
								if (match)
									[trigger fire];
							}
						}
					}
				}
			}
		}
	}
}

- (void) distanceTest:(MobileClient *) mobileDevice
{
	NSEnumerator * iter = [triggers objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [iter nextObject])
	{
		if ([[trigger valueForKey:@"trigger_type"] isEqual:LOCATION_TRIGGER])
		{
			NSString * deviceString = [NSString stringWithFormat:@"%@ (%@)", [mobileDevice name], [mobileDevice identifier]];

			if ([deviceString isEqual:[trigger valueForKey:@"mobile_device_name"]])
			{
				// http://www.movable-type.co.uk/scripts/latlong.html
				
				double deviceLat = [[mobileDevice valueForKey:@"mobile_latitude"] doubleValue] * ((2 * M_PI) / 360);
				double deviceLong = [[mobileDevice valueForKey:@"mobile_longitude"] doubleValue] * ((2 * M_PI) / 360);

				double siteLat = [[[PreferencesManager sharedInstance] valueForKey:@"site_latitude"] doubleValue] * ((2 * M_PI) / 360);
				double siteLong = [[[PreferencesManager sharedInstance] valueForKey:@"site_longitude"] doubleValue] * ((2 * M_PI) / 360);

				double earth = 6371000;

				double latDelta = deviceLat - siteLat;
				double longDelta = deviceLong - siteLong;

				double a = pow(sin(latDelta / 2), 2) + (cos(deviceLat) * cos(siteLat) * pow(sin(longDelta), 2));
				double c = 2 * atan2(sqrt(a), sqrt(1 - a));
				
				double distance = earth * c;
				
				NSNumber * direction = [trigger valueForKey:@"mobile_direction"];
				
				BOOL closer = YES;
				
				if ([direction intValue] == 1)
					closer = NO;
				
				BOOL fired = [[trigger valueForKey:@"mobile_fired"] boolValue];
				
				double border = [[trigger valueForKey:@"mobile_distance"] doubleValue];
				
				if (distance < border)
				{
					if (closer && !fired)
					{
						[trigger fire];
						
						[trigger setValue:[NSNumber numberWithBool:YES] forKey:@"mobile_fired"];
					}
					else if (!closer)
						[trigger setValue:[NSNumber numberWithBool:NO] forKey:@"mobile_fired"];
				}
				else
				{
					if (!closer && !fired)
					{
						[trigger fire];
						
						[trigger setValue:[NSNumber numberWithBool:YES] forKey:@"mobile_fired"];
					}
					else if (closer)
						[trigger setValue:[NSNumber numberWithBool:NO] forKey:@"mobile_fired"];
				}
			}
		}
	}
}

- (Trigger *) triggerWithIdentifier:(NSString *) identifier
{
	Trigger * finalTrigger = nil;

	NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
	
	NSEnumerator * trigIter = [triggers objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [trigIter nextObject])
	{
		if (finalTrigger == nil && [[trigger identifier] isEqual:identifier])
			finalTrigger = trigger;
	}
	
	[innerPool drain];
	
	return finalTrigger;
}

@end
