//
//  Snapshot.m
//  Shion
//
//  Created by Chris Karr on 4/6/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Snapshot.h"

#import "ConsoleManager.h"
#import "DeviceManager.h"
#import "EventManager.h"
#import "PreferencesManager.h"

#define NAME @"name"
#define IDENTIFIER @"identifier"
#define CATEGORY @"category"
#define DEVICES @"devices"
#define CREATED @"created"
#define USED @"used"

#define SNAPSHOT_EXECUTE @"snapshot_execute"

@implementation Snapshot

- (NSData *) data
{
	return [NSArchiver archivedDataWithRootObject:self];
}

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		CFUUIDRef uuid = CFUUIDCreate(NULL);
		NSString * deviceId = [((NSString *) CFUUIDCreateString(NULL, uuid)) autorelease];
		[self setValue:deviceId forKey:IDENTIFIER];
		
		[self setCategory:@"Unknown Category"];
		
		CFRelease(uuid);
	}
	
	return self;
}

- (NSString *) identifier
{
	return [self valueForKey:IDENTIFIER];
}

- (NSString *) name
{
	return [self valueForKey:NAME];
}

- (void) setName:(NSString *) name
{
	[self setValue:name forKey:NAME];
}

- (NSString *) category
{
	return [self valueForKey:CATEGORY];
}

- (void) setCategory:(NSString *) category
{
	[self setValue:category forKey:CATEGORY];
}

+ (Snapshot *) snapshot
{
	Snapshot * snapshot = [Snapshot dictionary];
	[snapshot setValue:@"New Snapshot" forKey:NAME];
	[snapshot setValue:@"No Category" forKey:CATEGORY];
	[snapshot setValue:[NSDate date] forKey:CREATED];

	NSMutableArray * snapDevices = [NSMutableArray array];
	
	NSArray * devices = [[DeviceManager sharedInstance] devices];
	
	NSEnumerator * iter = [devices objectEnumerator];
	Device * device = nil;
	while (device = [iter nextObject])
	{
		NSDictionary * snapDict = [device snapshotValues];
		
		if ([[snapDict allKeys] count] > 0)
		{
			NSMutableDictionary * deviceValues = [NSMutableDictionary dictionaryWithDictionary:snapDict];
			[deviceValues setValue:[device identifier] forKey:IDENTIFIER];
			
			[snapDevices addObject:deviceValues];
		}
	}
	
	[snapshot setValue:snapDevices forKey:DEVICES];
	
	return snapshot;
}

- (void) setValue:(id) value forKey:(NSString *) key
{
	if ([key isEqual:SNAPSHOT_EXECUTE])
		[self execute];
	else 
		[super setValue:value forKey:key];
}

- (id) valueForKey:(NSString *) key
{
	if ([key isEqual:@"snapshotDevices"])
		return [self snapshotDevices];
	
	return [super valueForKey:key];
}

- (void) execute
{
	NSIndexPath * selectionPath = [[ConsoleManager sharedInstance] selectionIndexPath];

	[[ConsoleManager sharedInstance] willChangeValueForKey:NAV_TREE]; 

	NSArray * devices = [[DeviceManager sharedInstance] devices];
	
	NSEnumerator * iter = [[self valueForKey:DEVICES] objectEnumerator];
	NSDictionary * deviceDict = nil;
	while (deviceDict = [iter nextObject])
	{
		NSEnumerator * deviceIter = [devices objectEnumerator];
		Device * device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([[device identifier] isEqual:[deviceDict valueForKey:IDENTIFIER]])
			{
				NSEnumerator * keyIter = [[deviceDict allKeys] objectEnumerator];
				NSString * key  = nil;
				while (key = [keyIter nextObject])
				{
					if (![key isEqual:IDENTIFIER])
						[device setValue:[deviceDict valueForKey:key] forKey:key];
				}
			}
		}
	}

	[[EventManager sharedInstance] createEvent:@"snapshot" source:[self identifier] initiator:[self identifier]
								   description:[NSString stringWithFormat:@"Snapshot '%@' executed.", [self name]]
										 value:@"65535"];
	
	[self setValue:[NSDate date] forKey:USED];

	[[ConsoleManager sharedInstance] didChangeValueForKey:NAV_TREE]; 
	[[ConsoleManager sharedInstance] setSelectionPath:selectionPath];
}

- (NSArray *) snapshotDevices
{
	NSMutableArray * devices = [NSMutableArray array];
	
	NSEnumerator * iter = [[self valueForKey:DEVICES] objectEnumerator];
	NSDictionary * deviceDict = nil;
	while (deviceDict = [iter nextObject])
	{
		NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		Device * device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([[device identifier] isEqual:[deviceDict valueForKey:IDENTIFIER]])
			{
				NSMutableDictionary * snapDevice = [NSMutableDictionary dictionary];

				[snapDevice setValue:[device identifier] forKey:@"identifier"];
				[snapDevice setValue:[device name] forKey:@"name"];
				[snapDevice setValue:[device snapshotDescription:deviceDict] forKey:@"description"];
				[snapDevice setValue:[NSImage imageNamed:@"remove_device.png"] forKey:@"icon"];
				
				[devices addObject:snapDevice];
			}
		}
	}
	
	return devices;
}

+ (Snapshot *) snapshotFromData:(NSData *) data
{
	NSDictionary * dataDict = [NSUnarchiver unarchiveObjectWithData:data];
	
	return [Snapshot dictionaryWithDictionary:dataDict];
}

- (void) removeDevices:(NSArray *) identifiers
{
	[self willChangeValueForKey:@"snapshotDevices"];

	NSMutableArray * toRemove = [NSMutableArray array];

	NSMutableArray * devices = [self valueForKey:DEVICES];
	
	NSEnumerator * idIter = [identifiers objectEnumerator];
	NSString * identifier = nil;
	while (identifier = [idIter nextObject])
	{
		NSEnumerator * deviceIter = [devices objectEnumerator];
		NSDictionary * device = nil;
		while (device = [deviceIter nextObject])
		{
			if ([[device valueForKey:IDENTIFIER] isEqual:identifier])
			{
				Device * actualDevice = [[DeviceManager sharedInstance] deviceWithIdentifier:identifier];

				NSNumber * confirm = [[PreferencesManager sharedInstance] valueForKey:@"confirm_snapshot_device_delete"];
				
				if (confirm == nil || [confirm boolValue])
				{
					if (confirm == nil)
						[[PreferencesManager sharedInstance] setValue:[NSNumber numberWithBool:YES] forKey:@"confirm_snapshot_device_delete"];

					NSAlert * panel = [[[NSAlert alloc] init] autorelease];
					[panel setAlertStyle:NSWarningAlertStyle];
					[panel setMessageText:NSLocalizedString(@"Remove device from snapshot?", nil)];
					[panel setInformativeText:[NSString stringWithFormat:@"Are you sure that you wish to remove %@ from the current snapshot?", [actualDevice name]]];
					[panel addButtonWithTitle:NSLocalizedString(@"No", nil)];
					[panel addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
				
					if (getVersion() >= 0x1050)
					{
						[panel setShowsSuppressionButton:YES];
						NSButton * suppress = [panel suppressionButton];
						[[suppress cell] setControlSize:NSSmallControlSize];
						[suppress setTitle:NSLocalizedString(@"Do not ask for confirmation again.", nil)];
					
						[[suppress cell] setFont:[NSFont labelFontOfSize:11]];
					
						[suppress bind:@"value" toObject:[PreferencesManager sharedInstance]
						   withKeyPath:@"confirm_snapshot_device_delete" options:[NSDictionary dictionaryWithObject:@"NSNegateBoolean" forKey:NSValueTransformerNameBindingOption]];
					}

					if ([panel runModal] == NSAlertSecondButtonReturn)
						[toRemove addObject:device];
				}
				else
					[toRemove addObject:device];
			}
		}
	}
	
	[devices removeObjectsInArray:toRemove];
	
	[self didChangeValueForKey:@"snapshotDevices"];
}

- (NSScriptObjectSpecifier *) objectSpecifier
{
	NSScriptObjectSpecifier * devicesSpecifier = [NSApp objectSpecifier];
	
	return [[[NSNameSpecifier alloc] initWithContainerClassDescription:[devicesSpecifier containerClassDescription]
												   containerSpecifier:devicesSpecifier
																  key:@"snapshots"
																 name:[self name]] autorelease];
}

- (void) execute:(NSScriptCommand *) command
{
	[self execute];
}


@end
