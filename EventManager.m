//
//  EventManager.m
//  Shion
//
//  Created by Chris Karr on 4/7/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "EventManager.h"
#import "LogManager.h"
#import "DeviceManager.h"
#import "TriggerManager.h"
#import "SnapshotManager.h"
#import "ConsoleManager.h"

#import "PreferencesManager.h"
#import "NotificationManager.h"

#import "XMPPManager.h"

@implementation EventManager

static EventManager * sharedInstance = nil;

+ (EventManager *) sharedInstance
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

- (NSString *) eventStorageFolder 
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

- (void) saveEvents
{
	if (dirty)
	{
		NSString * storageFolder = [self eventStorageFolder];
	
		NSString * file = [storageFolder stringByAppendingPathComponent:@"Events.events"];

		NSData * data = [NSArchiver archivedDataWithRootObject:events];
		
		[data writeToFile:file atomically:YES];

		
		//		[NSArchiver archiveRootObject:events toFile:file];
		
		dirty = NO;
	}
}

- (void) loadEvents
{
	if ([events count] > 0)
		[events removeAllObjects];
	
	NSString * storageFolder = [self eventStorageFolder];
	
	NSString * file = @"Events.events";

	NSData * data = [NSData dataWithContentsOfFile:[storageFolder stringByAppendingPathComponent:file]];
			
	if (data)
	{
		NSArray * deviceEvents = [NSUnarchiver unarchiveObjectWithData:data];
		
		NSEnumerator * eventIter = [deviceEvents objectEnumerator];
		NSDictionary * eventDict = nil;
		while (eventDict = [eventIter nextObject])
		{
			Event * event = [Event dictionaryWithDictionary:eventDict];

			[events addObject:event];
		}
	}
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	[events sortUsingDescriptors:[NSArray arrayWithObject:sort]];
	
	[sort release];
}

- (id) init
{
	if (self = [super init])
	{
		windowController = [[NSWindowController alloc] initWithWindowNibName:@"EventsWindow" owner:self];
		events = [[NSMutableArray alloc] init];
		cache = [[NSMutableDictionary dictionary] retain];
		[self loadEvents];
		
		cleanupTimer = [[NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(cleanup:) userInfo:nil repeats:YES] retain];
		
		dirty = NO;
	}
	
	return self;
}

- (NSArray *) events
{
	return events;
}

- (void) cleanup:(NSTimer *) theTimer
{
	[self willChangeValueForKey:@"events"];
	
	NSNumber * days = [[PreferencesManager sharedInstance] valueForKey:@"log_days"];

	NSMutableArray * toRemove = [NSMutableArray array];
	
	NSEnumerator * iter = [events objectEnumerator];
	Event * event = nil;
	while (event = [iter nextObject])
	{
		NSDate * date = [event date];
		
		if (abs([date timeIntervalSinceNow]) > (60 * 60 * 24 * [days intValue]))
			[toRemove addObject:event];
	}
	
	if ([toRemove count] > 500)
		[toRemove setArray:[toRemove subarrayWithRange:NSMakeRange(0, 500)]];
	
	[events removeObjectsInArray:toRemove];
	
	[self saveEvents];

	[self didChangeValueForKey:@"events"];
}

- (Event *) createEvent:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			description:(NSString *) description value:(id) value;
{
	return [self createEvent:type source:sourceId initiator:initiator description:description value:value match:YES];
}

- (Event *) createEvent:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			description:(NSString *) description value:(id) value match:(BOOL) matchCheck;
{
	Event * lastEvent = [self lastUpdateForIdentifier:sourceId event:type];
	
	if (matchCheck && [[lastEvent type] isEqual:type] && [[lastEvent source] isEqual:sourceId] && [[lastEvent initiator] isEqual:initiator]
		&& [[lastEvent description] isEqual:description] && [[lastEvent value] isEqual:value] && ![type isEqual:@"snapshot"] && 
		![type isEqual:@"trigger"])
	{
		
	}
	else
	{
		[[ConsoleManager sharedInstance] willChangeValueForKey:NAV_TREE];
		[self willChangeValueForKey:@"events"];

		if ([initiator isEqual:@"User"])
		{
			NSMutableDictionary * logDict = [NSMutableDictionary dictionary];
			[logDict setValue:LOG_LOCAL_COMMAND forKey:@"Log Type"];
			[logDict setValue:description forKey:@"Log Description"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"Log Notification" object:nil userInfo:logDict];
		}
		else
		{
			NSMutableDictionary * logDict = [NSMutableDictionary dictionary];
			[logDict setValue:LOG_EXTERNAL_EVENTS forKey:@"Log Type"];
			[logDict setValue:description forKey:@"Log Description"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"Log Notification" object:nil userInfo:logDict];
		}

		Event * event = [Event eventWithType:type source:sourceId initiator:initiator description:description
									   value:value date:[NSDate date]];

		NSString * title = @"Shion";
		
		Device * device = [[DeviceManager sharedInstance] deviceWithIdentifier:sourceId];
		
		if (device != nil)
			title = [device name];
		else 
		{
			Snapshot * snapshot = [[SnapshotManager sharedInstance] snapshotWithIdentifier:sourceId];
			
			if (snapshot != nil)
				title = [snapshot name];
			else
			{
				Trigger * trigger = [[TriggerManager sharedInstance] triggerWithIdentifier:sourceId];
				
				if (trigger != nil)
					title = [trigger name];
			}
		}

		
		NSString * cacheKey = [NSString stringWithFormat:@"%@ - %@", sourceId, nil];
		[cache removeObjectForKey:cacheKey];
		
		cacheKey = [NSString stringWithFormat:@"%@ - %@", sourceId, type];
		[cache removeObjectForKey:cacheKey];
		
		[self willChangeValueForKey:@"events" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:event]];
		[events addObject:event];
		[self didChangeValueForKey:@"events" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:event]];

//		[[XMPPManager sharedInstance] updateStatus:description available:YES];

		[[NotificationManager sharedInstance] showMessage:description title:title icon:nil type:EVENT_NOTE];
		
		[[XMPPManager sharedInstance] broadcastEvent:event forIdentifier:sourceId];

		dirty = YES;
		
		[self didChangeValueForKey:@"events"];
		[[ConsoleManager sharedInstance] didChangeValueForKey:NAV_TREE];

		return event;
	}
	
	return nil;
}

- (Event *) lastUpdateForIdentifier:(NSString *) identifier event:(NSString *) eventType
{
	NSArray * itemArray = [self eventsForIdentifier:identifier];

	// Assumes chronological storage...
	
	Event * finalEvent = nil;
	
	NSEnumerator * iter = [itemArray reverseObjectEnumerator];
	Event * event = nil;
	while (event = [iter nextObject])
	{
		if (finalEvent == nil && [[event source] isEqual:identifier] && (eventType == nil || [[event type] isEqual:eventType]))
			finalEvent = event;
	}
		
	return finalEvent;
}

- (NSArray *) eventsForIdentifier:(NSString *) identifier
{
	return [self eventsForIdentifier:identifier event:nil];
}

- (NSArray *) eventsForIdentifier:(NSString *) identifier event:(NSString *) eventType
{
	NSString * cacheKey = [NSString stringWithFormat:@"%@ - %@", identifier, eventType];

	NSArray * cachedArray = [cache valueForKey:cacheKey];
	
	if (cachedArray != nil)
		return cachedArray;
	
	NSMutableArray * myEvents = [NSMutableArray array];

	NSEnumerator * eventIter = [events objectEnumerator];
	Event * event = nil;
	while (event = [eventIter nextObject])
	{
		if ([[event source] isEqual:identifier] && (eventType == nil || [[event type] isEqual:eventType]))
			[myEvents addObject:event];
	}
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	
	[myEvents sortUsingDescriptors:[NSArray arrayWithObject:sort]];
	
	[sort release];

	[cache setValue:myEvents forKey:cacheKey];
	
	return myEvents;
}

- (NSArray *) eventsTree
{
	NSMutableArray * tree = [NSMutableArray array];

	NSMutableDictionary * allDates = [NSMutableDictionary dictionary];
	NSMutableArray * dateStrings = [NSMutableArray array];
	
	NSMutableDictionary * byDate = [NSMutableDictionary dictionaryWithObject:@"By Date" forKey:@"label"];
	NSMutableArray * dateArray = [NSMutableArray array];
	[byDate setValue:dateArray forKey:@"children"];
	[byDate setValue:events forKey:EVENT_LIST];

	NSMutableDictionary * allDevices = [NSMutableDictionary dictionary];
	NSMutableDictionary * byDevice = [NSMutableDictionary dictionaryWithObject:@"By Device" forKey:@"label"];
	NSMutableArray * deviceArray = [NSMutableArray array];
	[byDevice setValue:deviceArray forKey:@"children"];
	NSMutableArray * allDeviceEvents = [NSMutableArray array];
	[byDevice setValue:allDeviceEvents forKey:EVENT_LIST];
	
	NSMutableDictionary * allSnapshots = [NSMutableDictionary dictionary];
	NSMutableDictionary * bySnapshot = [NSMutableDictionary dictionaryWithObject:@"By Snapshot" forKey:@"label"];
	NSMutableArray * snapshotArray = [NSMutableArray array];
	[bySnapshot setValue:snapshotArray forKey:@"children"];
	NSMutableArray * allSnapshotEvents = [NSMutableArray array];
	[bySnapshot setValue:allSnapshotEvents forKey:EVENT_LIST];

	NSMutableDictionary * allTriggers = [NSMutableDictionary dictionary];
	NSMutableDictionary * byTrigger = [NSMutableDictionary dictionaryWithObject:@"By Trigger" forKey:@"label"];
	NSMutableArray * triggerArray = [NSMutableArray array];
	[byTrigger setValue:triggerArray forKey:@"children"];
	NSMutableArray * allTriggerEvents = [NSMutableArray array];
	[byTrigger setValue:allTriggerEvents forKey:EVENT_LIST];

	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	
	NSEnumerator * eventIter = [[events sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] objectEnumerator];

	[sort release];
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	[formatter setDateStyle:NSDateFormatterLongStyle];
	
	Event * event = nil;
	while (event = [eventIter nextObject])
	{
		NSDate * date = [event date];
		
		NSString * dateString = [formatter stringFromDate:date];
		
		NSMutableArray * dateArray = [allDates valueForKey:dateString];
	
		if (dateArray == nil)
		{
			dateArray = [NSMutableArray array];
			[allDates setValue:dateArray forKey:dateString];
			
			[dateStrings addObject:dateString];
		}
		
		[dateArray addObject:event];
		
		NSString * source = [event source];
		
		Device * device = [[DeviceManager sharedInstance] deviceWithIdentifier:source];
		
		if (device != nil)
		{
			NSMutableArray * deviceArray = [allDevices valueForKey:[device identifier]];
			
			if (deviceArray == nil)
			{
				deviceArray = [NSMutableArray array];
				[allDevices setValue:deviceArray forKey:[device identifier]];
			}
			
			[deviceArray addObject:event];
			[allDeviceEvents addObject:event];
		}

		Snapshot * snapshot = [[SnapshotManager sharedInstance] snapshotWithIdentifier:source];
		
		if (snapshot != nil)
		{
			NSMutableArray * snapArray = [allSnapshots valueForKey:[snapshot identifier]];
			
			if (snapArray == nil)
			{
				snapArray = [NSMutableArray array];
				[allSnapshots setValue:snapArray forKey:[snapshot identifier]];
			}
			
			[snapArray addObject:event];
			[allSnapshotEvents addObject:event];
		}

		Trigger * trigger = [[TriggerManager sharedInstance] triggerWithIdentifier:source];
		
		if (trigger != nil)
		{
			NSMutableArray * trigArray = [allTriggers valueForKey:[trigger identifier]];
			
			if (trigArray == nil)
			{
				trigArray = [NSMutableArray array];
				[allTriggers setValue:trigArray forKey:[trigger identifier]];
			}
			
			[trigArray addObject:event];
			[allTriggerEvents addObject:event];
		}
	}
	
	[formatter release];
	
	NSEnumerator * dateIter = [dateStrings objectEnumerator];
	NSString * dateString = nil;
	while (dateString = [dateIter nextObject])
	{
		NSMutableDictionary * dateDict = [NSMutableDictionary dictionaryWithObject:dateString forKey:@"label"];
		
		[dateDict setValue:[allDates valueForKey:dateString] forKey:EVENT_LIST];

		[dateArray addObject:dateDict];
	}

	NSArray * devices = [[DeviceManager sharedInstance] devices];
	NSEnumerator * deviceIter = [devices objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		NSArray * deviceEvents = [allDevices valueForKey:[device identifier]];
		
		if (deviceEvents != nil)
		{
			NSMutableDictionary * deviceDict = [NSMutableDictionary dictionaryWithObject:[device name] forKey:@"label"];
			
			[deviceDict setValue:deviceEvents forKey:EVENT_LIST];
			
			[deviceArray addObject:deviceDict];
		}
	}

	NSArray * snapshots = [[SnapshotManager sharedInstance] snapshots];
	NSEnumerator * snapIter = [snapshots objectEnumerator];
	Snapshot * snapshot = nil;
	while (snapshot = [snapIter nextObject])
	{
		NSArray * snapEvents = [allSnapshots valueForKey:[snapshot identifier]];
		
		if (snapEvents != nil)
		{
			NSMutableDictionary * snapDict = [NSMutableDictionary dictionaryWithObject:[snapshot name] forKey:@"label"];
			
			[snapDict setValue:snapEvents forKey:EVENT_LIST];
			
			[snapshotArray addObject:snapDict];
		}
	}

	NSArray * triggers = [[TriggerManager sharedInstance] triggers];
	NSEnumerator * trigIter = [triggers objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [trigIter nextObject])
	{
		NSArray * trigEvents = [allTriggers valueForKey:[trigger identifier]];
		
		if (trigEvents != nil)
		{
			NSMutableDictionary * trigDict = [NSMutableDictionary dictionaryWithObject:[trigger name] forKey:@"label"];
			
			[trigDict setValue:trigEvents forKey:EVENT_LIST];
			
			[triggerArray addObject:trigDict];
		}
	}
	
	[tree addObject:byDate];
	[tree addObject:byDevice];
	[tree addObject:bySnapshot];
	[tree addObject:byTrigger];
	
	return tree;
}

@end
