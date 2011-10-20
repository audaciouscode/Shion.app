//
//  DialogManager.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "DialogManager.h"
#import "DeviceManager.h"
#import "SnapshotManager.h"
#import "EventManager.h"

#import "Commands.h"

int sortDevicesByLength (id one, id two, void *context)
{
	if ([[one name] length] < [[two name] length])
		return NSOrderedAscending;
	else if ([[one name] length] > [[two name] length])
		return NSOrderedDescending;

	return NSOrderedSame;
}

int sortSnapshotsByLength (id one, id two, void *context)
{
	if ([[one name] length] < [[two name] length])
		return NSOrderedAscending;
	else if ([[one name] length] > [[two name] length])
		return NSOrderedDescending;

	return NSOrderedSame;
}

@implementation DialogManager

static DialogManager * sharedInstance = nil;

+ (DialogManager *) sharedInstance
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


- (id) findObject:(NSString *) userText
{
	id object = nil;
	
	NSString * lowerUsertext = [userText lowercaseString];
	
	NSMutableArray * deviceMatches = [NSMutableArray array];

	// Look for device sharing name
	NSEnumerator * iter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * device = nil;
	while (device = [iter nextObject])
	{
		NSString * name = [device name];
		
		if ([lowerUsertext rangeOfString:[name lowercaseString]].location != NSNotFound)
			[deviceMatches addObject:device];
	}
	
	if ([deviceMatches count] > 0)
	{
		if ([deviceMatches count] > 1)
		{
			[deviceMatches sortUsingFunction:sortDevicesByLength context:NULL];
			
			object = [deviceMatches objectAtIndex:0];
		}
		else
			object = [deviceMatches lastObject];
	}
	else
	{
		// Look for snapshots

		NSMutableArray * snapMatches = [NSMutableArray array];

		NSEnumerator * iter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
		Snapshot * snapshot = nil;
		while (snapshot = [iter nextObject])
		{
			NSString * name = [snapshot name];
			
			if ([lowerUsertext rangeOfString:[name lowercaseString]].location != NSNotFound)
				[snapMatches addObject:snapshot];
		}
		
		if ([snapMatches count] > 0)
		{
			if ([snapMatches count] > 1)
			{
				[snapMatches sortUsingFunction:sortSnapshotsByLength context:NULL];
				
				object = [snapMatches objectAtIndex:0];
			}
			else
				object = [snapMatches lastObject];
		}
	}
	
	return object;
}

- (Command *) findCommandForString:(NSString *) userText using:(id) object
{
	NSMutableString * lowerText = [NSMutableString stringWithString:[userText lowercaseString]];

	if ([object isKindOfClass:[Device class]])
	{
		[lowerText replaceOccurrencesOfString:[[object name] lowercaseString] withString:@"***" options:0 range:NSMakeRange(0, [lowerText length])];

		 DeviceCommand * command = nil;

		if ([lowerText rangeOfString:@"deactivate" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeactivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"turn *** off" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeactivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"turn off ***" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeactivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"shut down ***" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeactivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"activate" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[ActivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"turn *** on" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[ActivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"turn on ***" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[ActivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"ring" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[ActivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"status" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeviceStatusCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"details" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeviceStatusCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"inspect" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeviceStatusCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"brighten" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[BrightenDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"dim" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DimDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"set *** level to" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
		{
			[lowerText replaceOccurrencesOfString:@"set *** level to" withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];

			[lowerText replaceOccurrencesOfString:@" " withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			int level = [lowerText intValue];
			
			SetDeviceLevelCommand * setCommand = [[[SetDeviceLevelCommand alloc] init] autorelease];
			[setCommand setLevel:level];
			
			command = setCommand;
		}
		else if ([lowerText rangeOfString:@"set *** to" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
		{
			[lowerText replaceOccurrencesOfString:@"set *** to" withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			[lowerText replaceOccurrencesOfString:@" " withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			int level = [lowerText intValue];
			
			SetDeviceLevelCommand * setCommand = [[[SetDeviceLevelCommand alloc] init] autorelease];
			[setCommand setLevel:level];
			
			command = setCommand;
		}
		else if ([lowerText rangeOfString:@"set *** mode to" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
		{
			[lowerText replaceOccurrencesOfString:@"set *** mode to" withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			[lowerText replaceOccurrencesOfString:@" " withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			
			SetThermostatModeCommand * setCommand = [[[SetThermostatModeCommand alloc] init] autorelease];
			[setCommand setMode:lowerText];
			
			command = setCommand;
		}
		else if ([lowerText rangeOfString:@"set *** cool point to" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
		{
			[lowerText replaceOccurrencesOfString:@"set *** cool point to" withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			[lowerText replaceOccurrencesOfString:@" " withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			
			SetThermostatCoolPointCommand * setCommand = [[[SetThermostatCoolPointCommand alloc] init] autorelease];
			[setCommand setCool:[lowerText intValue]];
			
			command = setCommand;
		}
		else if ([lowerText rangeOfString:@"set *** heat point to" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
		{
			[lowerText replaceOccurrencesOfString:@"set *** heat point to" withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			[lowerText replaceOccurrencesOfString:@" " withString:@"" 
										  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [lowerText length])];
			
			
			SetThermostatHeatPointCommand * setCommand = [[[SetThermostatHeatPointCommand alloc] init] autorelease];
			[setCommand setHeat:[lowerText intValue]];
			
			command = setCommand;
		}
		else if ([lowerText rangeOfString:@"toggle *** fan" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[ToggleThermostatFanCommand alloc] init] autorelease];
		else if ([lowerText isEqual:@"***"])
			command = [[[DeviceStatusCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"*** off" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeactivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"*** on" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[ActivateDeviceCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"turn *** devices off" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeactivateHouseDevicesCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"turn *** lights off" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[DeactivateHouseLightsCommand alloc] init] autorelease];
		else if ([lowerText rangeOfString:@"turn *** lights on" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[ActivateHouseLightsCommand alloc] init] autorelease];

		if (command != nil)
			[command setDevice:object];
		
		return command;
	}
	else if ([object isKindOfClass:[Snapshot class]])
	{
		[lowerText replaceOccurrencesOfString:[[object name] lowercaseString] withString:@"***" options:0 range:NSMakeRange(0, [lowerText length])];
		
		SnapshotCommand * command = nil;
		
		if ([lowerText rangeOfString:@"activate" options:0 range:NSMakeRange(0, [lowerText length])].location != NSNotFound)
			command = [[[ActivateSnapshotCommand alloc] init] autorelease];

		if (command != nil)
			[command setSnaphot:object];
		
		return command;
	}

	return nil;
}

- (Command *) findSystemCommand:(NSString *) userText
{
	NSString * lower = [userText lowercaseString];
	
	if ([lower isEqual:@"status"])
		return [[[SystemStatusCommand alloc] init] autorelease];
	else if ([lower isEqual:@"devices"])
		return [[[ListDevicesCommand alloc] init] autorelease];
	else if ([lower isEqual:@"snapshots"])
		return [[[ListSnapshotsCommand alloc] init] autorelease];
	else
		return nil;
}

- (Command *) commandForString:(NSString *) userText
{
	[[EventManager sharedInstance] createEvent:@"dialog" source:@"dialog_manager" initiator:@"User" 
								   description:[NSString stringWithFormat:@"Received dialog command: %@", userText] value:userText];
	 
	id object = [self findObject:userText];
	Command * command = nil;
	
	if (object != nil)
		command = [self findCommandForString:userText using:object];
	else
		command = [self findSystemCommand:userText];

	return command;
}

@end
