//
//  Trigger.m
//  Shion
//
//  Created by Chris Karr on 5/4/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Trigger.h"

#import "SnapshotManager.h"
#import "TriggerManager.h"
#import "EventManager.h"
#import "ConsoleManager.h"

#define TRIGGER_TYPE @"trigger_type"
#define TRIGGER_ACTION @"trigger_action"
#define CREATED @"created"
#define FIRED @"fired"

#define IDENTIFIER @"identifier"

@implementation Trigger


+ (Trigger *) triggerForType:(NSString *) type
{
	Trigger * trigger = [Trigger dictionary];
	
	[trigger setValue:[NSString stringWithFormat:@"New %@ Trigger", type] forKey:TRIGGER_NAME];
	[trigger setValue:@"None" forKey:TRIGGER_ACTION];
	
	[trigger setType:type];
	
	return trigger;
}

+ (Trigger *) triggerFromData:(NSData *) data
{
	NSDictionary * dataDict = [NSUnarchiver unarchiveObjectWithData:data];
	
	return [Trigger dictionaryWithDictionary:dataDict];
}

- (void) setType:(NSString *) type
{
	[self setValue:type forKey:TRIGGER_TYPE];
}

- (NSString *) type
{
	return [self valueForKey:TRIGGER_TYPE];
}

- (NSString *) name
{
	return [self valueForKey:TRIGGER_NAME];
}

- (NSString *) identifier
{
	return [self valueForKey:IDENTIFIER];
}

- (NSData *) data
{
	return [NSArchiver archivedDataWithRootObject:self];
}

- (NSString *) action
{
	return [self valueForKey:TRIGGER_ACTION];
}

- (id) valueForKey:(NSString *) key
{
	if ([key isEqual:@"action_name"])
	{
		if ([[self valueForKey:@"trigger_action"] isEqual:@"Snapshot"])
		{
			NSString * value = @"Snapshot: Unknown or removed";
			NSEnumerator * iter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
			Snapshot * snapshot = nil;
			while (snapshot = [iter nextObject])
			{
				if ([[snapshot identifier] isEqual:[self valueForKey:@"snapshot"]])
					value = [NSString stringWithFormat:@"Snapshot: %@", [snapshot name]];
			}
			
			return value;
		}
		else if ([[self valueForKey:@"trigger_action"] isEqual:@"Script"])
		{
			return [self valueForKey:@"script"];
		}
	}
	else if ([key isEqual:@"description"])
		return [self description];
	else if ([key isEqual:@"events"])
		return [[EventManager sharedInstance] eventsForIdentifier:[self identifier]];
	else if ([key isEqual:@"name"])
		return [self name];
		
	return [super valueForKey:key];
}


- (void) setValue:(id)value forKey:(NSString *)key
{
	if ([key isEqual:@"trigger_action"])
	{
		[super setValue:value forKey:key];

		/* if ([value isEqual:@"Snapshot"])
			[[NSNotificationCenter defaultCenter] postNotificationName:NEED_SNAPSHOT object:self];
		else if ([value isEqual:@"Script"])
			[[NSNotificationCenter defaultCenter] postNotificationName:NEED_SCRIPT object:self]; */
	}
	else if ([key isEqual:@"snapshot"])
	{
		[self willChangeValueForKey:@"action_name"];
		
		[super setValue:value forKey:key];
		
		[self didChangeValueForKey:@"action_name"];
	}
	else if ([key isEqual:@"script"])
	{
		[self willChangeValueForKey:@"action_name"];
		
		[super setValue:value forKey:key];
		
		[self didChangeValueForKey:@"action_name"];
	}
	else
		[super setValue:value forKey:key];
}

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		CFUUIDRef uuid = CFUUIDCreate(NULL);
		NSString * deviceId = [((NSString *) CFUUIDCreateString(NULL, uuid)) autorelease];
		[self setValue:deviceId forKey:IDENTIFIER];
		[self setValue:[NSDate date] forKey:CREATED];
		
		[self setType:@"None"];
		
		CFRelease(uuid);
	}
	
	return self;
}

- (void) fire
{
	[self willChangeValueForKey:@"events"];

	NSIndexPath * selectionPath = [[ConsoleManager sharedInstance] selectionIndexPath];
	
	[[ConsoleManager sharedInstance] willChangeValueForKey:NAV_TREE]; 

	[[EventManager sharedInstance] createEvent:@"trigger" source:[self identifier] initiator:[self identifier]
								   description:[NSString stringWithFormat:@"Trigger '%@' fired.", [self name]]
										 value:@"65535"];
	
	[self willChangeValueForKey:FIRED];
	
	[self setValue:[NSDate date] forKey:FIRED];
	
	if ([[self valueForKey:@"trigger_action"] isEqual:@"Snapshot"])
	{
		NSEnumerator * iter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
		Snapshot * snapshot = nil;
		while (snapshot = [iter nextObject])
		{
			if ([[snapshot identifier] isEqual:[self valueForKey:@"snapshot"]])
				[snapshot execute];
		}
	}		
	else if ([[self valueForKey:@"trigger_action"] isEqual:@"Script"] && [self valueForKey:@"script"] != nil)
		[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:[NSArray arrayWithObject:[self valueForKey:@"script"]]];

	if ([self valueForKey:@"sound_alert"] != nil && [[self valueForKey:@"sound_alert"] boolValue])
		NSBeep();
	
	[self didChangeValueForKey:FIRED];

	[[ConsoleManager sharedInstance] didChangeValueForKey:NAV_TREE]; 
	
	[[ConsoleManager sharedInstance] setSelectionPath:selectionPath];

	[self didChangeValueForKey:@"events"];
}

- (NSString *) description
{
	if ([[self valueForKey:@"trigger_type"] isEqual:DATE_TRIGGER])
	{
		NSDateFormatter * hourAndMinute = [[NSDateFormatter alloc] init];
		[hourAndMinute setDateFormat:@"HH:mm"];
		
		NSString * timeString = [hourAndMinute stringFromDate:[self valueForKey:@"date_time"]];
		
		[hourAndMinute release];
		
		NSMutableString * condition = [NSMutableString stringWithFormat:@"Time of day is %@. (", timeString];

		if ([[self valueForKey:@"date_sunday"] boolValue])
			[condition appendString:@"S"];

		if ([[self valueForKey:@"date_monday"] boolValue])
			[condition appendString:@"M"];

		if ([[self valueForKey:@"date_tuesday"] boolValue])
			[condition appendString:@"T"];

		if ([[self valueForKey:@"date_wednesday"] boolValue])
			[condition appendString:@"W"];

		if ([[self valueForKey:@"date_thursday"] boolValue])
			[condition appendString:@"Th"];

		if ([[self valueForKey:@"date_friday"] boolValue])
			[condition appendString:@"F"];

		if ([[self valueForKey:@"date_saturday"] boolValue])
			[condition appendString:@"Sa"];
		
		[condition appendString:@")"];
		
		return condition;
	}
	else if ([[self valueForKey:@"trigger_type"] isEqual:SOLAR_TRIGGER])
	{
		NSString * minutes = nil;
		NSString * delta = nil;
		
		if ([self valueForKey:@"sunrise_minutes"] != nil)
		{
			minutes = [NSString stringWithFormat:@"%@", [self valueForKey:@"sunrise_minutes"]];
			
			if ([[self valueForKey:@"sunrise_before_after"] isEqual:@"before"])
				delta = @"before";
			else if ([[self valueForKey:@"sunrise_before_after"] isEqual:@"after"])
				delta = @"after";
		}
		
		if ([[self valueForKey:@"sunrise_or_sunset"] isEqual:@"Sunset"] && minutes != nil && delta != nil)
			return [NSString stringWithFormat:@"%@ minutes %@ sunset.", minutes, delta];
		else if ([[self valueForKey:@"sunrise_or_sunset"] isEqual:@"Sunrise"] && minutes != nil && delta != nil)
			return [NSString stringWithFormat:@"%@ minutes %@ sunrise.", minutes, delta];
		else
			return [self valueForKey:@"sunrise_or_sunset"];			
	}
	else if ([[self valueForKey:@"trigger_type"] isEqual:X10_TRIGGER] && [self valueForKey:@"xten_address"] != nil)
	{
		NSMutableString * condition = [NSMutableString stringWithFormat:@"X10 Command: %@", [self valueForKey:@"xten_address"]];
		
		if ([[self valueForKey:@"xten_on"] boolValue])
			[condition appendString:@" On"];
		else if ([[self valueForKey:@"xten_off"] boolValue])
			[condition appendString:@" Off"];
		else if ([[self valueForKey:@"xten_brighten"] boolValue])
			[condition appendString:@" Brighten"];
		else if ([[self valueForKey:@"xten_dim"] boolValue])
			[condition appendString:@" Dim"];
		
		return condition;
	}
	else if ([[self valueForKey:@"trigger_type"] isEqual:MOTION_TRIGGER])
	{
		if ([[self valueForKey:@"motion_cease"] boolValue])
			return [NSString stringWithFormat:@"Motion Ceased: %@", [self valueForKey:@"motion_sensor"]];
		else if ([[self valueForKey:@"motion_detect"] boolValue])
			return [NSString stringWithFormat:@"Motion Detected: %@", [self valueForKey:@"motion_sensor"]];
	}
	else if ([[self valueForKey:@"trigger_type"] isEqual:APERTURE_TRIGGER])
	{
		if ([[self valueForKey:@"aperture_closes"] boolValue])
			return [NSString stringWithFormat:@"Aperture Closed: %@", [self valueForKey:@"aperture_sensor"]];
		else if ([[self valueForKey:@"aperture_opens"] boolValue])
			return [NSString stringWithFormat:@"Aperture Opened: %@", [self valueForKey:@"aperture_sensor"]];
	}
	else if ([[self valueForKey:@"trigger_type"] isEqual:TEMPERATURE_TRIGGER])
	{
		NSNumber * triggerTemp = [self valueForKey:@"temperature_degrees"];
		
		if (triggerTemp == nil)
			triggerTemp = [NSNumber numberWithInt:100];
		
		if ([self valueForKey:@"temperature_direction"] == nil)
			[self setValue:@"rises above" forKey:@"temperature_direction"];

		return [NSString stringWithFormat:@"Temperature %@ %@°.", [self valueForKey:@"temperature_direction"], triggerTemp];
	}		
	else if ([[self valueForKey:@"trigger_type"] isEqual:PHONE_TRIGGER])
	{
		NSString * callerMatch = [self valueForKey:@"phone_caller"];
		NSString * phoneMatch = [self valueForKey:@"phone_number"];
		
		if (callerMatch != nil)
			return [NSString stringWithFormat:@"Incoming caller matches '%@'.", callerMatch];
		else if (phoneMatch != nil)
			return [NSString stringWithFormat:@"Incoming phone numbr matches '%@'.", phoneMatch];
	}
	
	return @"Unknown or invalid conditions.";
}

- (NSDate *) fired
{
	return [self valueForKey:FIRED];
}

- (NSString *) actionDescription
{
	if ([[self valueForKey:@"trigger_action"] isEqual:@"Snapshot"])
	{
		NSString * value = @"Snapshot: Unknown or removed";
		NSEnumerator * iter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
		Snapshot * snapshot = nil;
		while (snapshot = [iter nextObject])
		{
			if ([[snapshot identifier] isEqual:[self valueForKey:@"snapshot"]])
				value = [NSString stringWithFormat:@"Snapshot: %@", [snapshot name]];
		}
		
		return value;
	}
	else if ([[self valueForKey:@"trigger_action"] isEqual:@"Script"])
		return [NSString stringWithFormat:@"Script: %@", [[self valueForKey:@"script"] lastPathComponent]];
	
	return @"No action specified.";
}	

- (NSScriptObjectSpecifier *) objectSpecifier
{
	NSScriptObjectSpecifier * devicesSpecifier = [NSApp objectSpecifier];
	
	return [[[NSNameSpecifier alloc] initWithContainerClassDescription:[devicesSpecifier containerClassDescription]
												   containerSpecifier:devicesSpecifier
																  key:@"triggers"
																 name:[self name]] autorelease];
}

- (void) fire:(NSScriptCommand *) command
{
	[self fire];
}


@end
