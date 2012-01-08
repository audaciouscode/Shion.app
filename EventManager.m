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

- (NSString *) applicationSupportDirectory 
{
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();

    return [basePath stringByAppendingPathComponent:@"Shion"];
}

- (NSManagedObjectModel *)managedObjectModel 
{
    if (managedObjectModel) 
		return managedObjectModel;
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    

    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator 
{
    if (persistentStoreCoordinator) 
		return persistentStoreCoordinator;
	
    NSManagedObjectModel * mom = [self managedObjectModel];
	
    if (!mom) 
	{
        NSAssert(NO, @"Managed object model is nil");
        NSLog(@"%@:%s No model to generate a store from", [self class], _cmd);
        return nil;
    }
	
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * applicationSupportDirectory = [self applicationSupportDirectory];
    NSError * error = nil;
    
    if (![fileManager fileExistsAtPath:applicationSupportDirectory isDirectory:NULL] )
	{
		if (![fileManager createDirectoryAtPath:applicationSupportDirectory attributes:[NSDictionary dictionary]])
		{
            NSAssert(NO, ([NSString stringWithFormat:@"Failed to create App Support directory %@ : %@", applicationSupportDirectory, error]));
            NSLog(@"Error creating application support directory at %@ : %@", applicationSupportDirectory,error);
            return nil;
		}
    }
    
    NSURL * url = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent:@"Events.storedata"]];
	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
	
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												  configuration:nil 
															URL:url 
														options:nil 
														  error:&error])
	{
        [[NSApplication sharedApplication] presentError:error];
        [persistentStoreCoordinator release];
		persistentStoreCoordinator = nil;
		
        return nil;
    }    
	
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *) managedObjectContext 
{
    if (managedObjectContext)
		return managedObjectContext;
	
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];

    if (!coordinator) 
	{
        NSMutableDictionary * dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];

        return nil;
    }
	
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
	
    return managedObjectContext;
}

- (void) saveEvents
{
	if (dirty)
	{
		NSError *error = nil;
		
		if (![[self managedObjectContext] commitEditing])
			NSLog(@"%@:%s unable to commit editing before saving", [self class], _cmd);
		
		if (![[self managedObjectContext] save:&error])
			[[NSApplication sharedApplication] presentError:error];
		
		dirty = NO;
	}
}

- (id) init
{
	if (self = [super init])
	{
		windowController = [[NSWindowController alloc] initWithWindowNibName:@"EventsWindow" owner:self];
		cache = [[NSMutableDictionary dictionary] retain];
		_timelineCache = [[NSMutableDictionary alloc] init];
		
		cleanupTimer = [[NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(cleanup:) userInfo:nil repeats:YES] retain];
		
		dirty = NO;
	}
	
	return self;
}

- (NSMutableDictionary *) timelineCache
{
	return _timelineCache;
}

- (NSArray *) events
{
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	[request setSortDescriptors:[NSArray arrayWithObject:sort]];
	[sort release];
	
	NSError * error = nil;
	NSArray * array = [[self managedObjectContext] executeFetchRequest:request error:&error];
	
	if (array != nil)
		return array;
	
	return [NSArray array];
}

- (void) cleanup:(NSTimer *) theTimer
{
	[self willChangeValueForKey:@"events"];

	NSManagedObjectContext * context = [self managedObjectContext];
	
	NSNumber * days = [[PreferencesManager sharedInstance] valueForKey:@"log_days"];

	NSDate * cutOff = [NSDate dateWithTimeIntervalSinceNow:(-60 * 60 * 24 * [days intValue])];

	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(date < %@)", cutOff];
	[request setPredicate:predicate];
	
	NSError * error = nil;
	NSArray * array = [[self managedObjectContext] executeFetchRequest:request error:&error];
	
	if (array != nil && [array count] > 0)
	{
		NSEnumerator * iter = [array objectEnumerator];
		NSManagedObject * event = nil;
		while (event = [iter nextObject])
		{
			[context deleteObject:event];
		}
	}	
	
	[self saveEvents];

	[self didChangeValueForKey:@"events"];
}

- (NSManagedObject *) createEvent:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			description:(NSString *) description value:(NSString *) value;
{
	return [self createEvent:type source:sourceId initiator:initiator description:description value:value match:YES];
}

- (NSManagedObject *) createEvent:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			description:(NSString *) description value:(NSString *) value match:(BOOL) matchCheck;
{
	NSManagedObject * lastEvent = [self lastUpdateForIdentifier:sourceId event:type];
	
	if (matchCheck && [[lastEvent valueForKey:@"type"] isEqual:type] && [[lastEvent valueForKey:@"source"] isEqual:sourceId] && 
		[[lastEvent valueForKey:@"initiator"] isEqual:initiator] && [[lastEvent valueForKey:@"event_description"] isEqual:description] && 
		[[lastEvent valueForKey:@"value"] isEqual:value] && ![type isEqual:@"snapshot"] && ![type isEqual:@"trigger"])
	{
		
	}
	else
	{
		[[ConsoleManager sharedInstance] willChangeValueForKey:NAV_TREE];
		[self willChangeValueForKey:@"events"];
		
		NSEnumerator * iter = [[_timelineCache allKeys] objectEnumerator];
		NSString * key = nil;
		while (key = [iter nextObject])
		{
			if ([key rangeOfString:sourceId].location != NSNotFound)
				[_timelineCache removeObjectForKey:key];
		}

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

		NSManagedObject * event = [NSEntityDescription insertNewObjectForEntityForName:@"Event"
																inManagedObjectContext:[self managedObjectContext]];
		[event setValue:type forKey:@"type"];
		[event setValue:sourceId forKey:@"source"];
		[event setValue:initiator forKey:@"initiator"];
		[event setValue:description forKey:@"event_description"];
		[event setValue:[NSDate date] forKey:@"date"];
		[event setValue:value forKey:@"value"];

		[self willChangeValueForKey:@"events" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:event]];

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
		
//		[[XMPPManager sharedInstance] updateStatus:description available:YES];

		[[NotificationManager sharedInstance] showMessage:description title:title icon:nil type:EVENT_NOTE];
		
		[[XMPPManager sharedInstance] broadcastEvent:event forIdentifier:sourceId];

		dirty = YES;
		
		[self didChangeValueForKey:@"events"];
		[[ConsoleManager sharedInstance] didChangeValueForKey:NAV_TREE];

		[self didChangeValueForKey:@"events" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:event]];

		return event;
	}
	
	return nil;
}

- (NSManagedObject *) lastUpdateForIdentifier:(NSString *) identifier event:(NSString *) eventType
{
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	[request setFetchLimit:1];
	
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(source == %@) AND (type == %@)", identifier, eventType];
	
	if (eventType == nil)
		predicate = [NSPredicate predicateWithFormat:@"(source == %@)", identifier];
	
	[request setPredicate:predicate];
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	[request setSortDescriptors:[NSArray arrayWithObject:sort]];
	[sort release];
	
	NSError * error = nil;
	NSArray * array = [[self managedObjectContext] executeFetchRequest:request error:&error];

	if (array != nil && [array count] > 0)
		return [array objectAtIndex:0];
		
	return nil;
}

- (NSArray *) eventsForIdentifier:(NSString *) identifier
{
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(source == %@)", identifier];
	[request setPredicate:predicate];
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sort]];
	[sort release];
	
	NSError * error = nil;
	NSArray * array = [[self managedObjectContext] executeFetchRequest:request error:&error];
	
	if (array != nil)
		return array;
	
	return [NSArray array];
}

- (NSArray *) eventsForIdentifier:(NSString *) identifier event:(NSString *) eventType
{
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entity];
	
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"(source == %@) AND (type == %@)", identifier, eventType];
	[request setPredicate:predicate];
	
	NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sort]];
	[sort release];
	
	NSError * error = nil;
	NSArray * array = [[self managedObjectContext] executeFetchRequest:request error:&error];
	
	if (array != nil)
		return array;
	
	return [NSArray array];
}

- (NSArray *) eventsTree
{
	NSMutableArray * tree = [NSMutableArray array];

	NSMutableDictionary * allDates = [NSMutableDictionary dictionary];
	NSMutableArray * dateStrings = [NSMutableArray array];
	
	NSMutableDictionary * byDate = [NSMutableDictionary dictionaryWithObject:@"By Date" forKey:@"label"];
	NSMutableArray * dateArray = [NSMutableArray array];
	[byDate setValue:dateArray forKey:@"children"];
	[byDate setValue:[self events] forKey:EVENT_LIST];

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

	NSEnumerator * eventIter = [[self events] objectEnumerator];
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	[formatter setDateStyle:NSDateFormatterLongStyle];
	
	NSManagedObject * event = nil;
	while (event = [eventIter nextObject])
	{
		NSDate * date = [event valueForKey:@"date"];
		
		NSString * dateString = [formatter stringFromDate:date];
		
		NSMutableArray * dateArray = [allDates valueForKey:dateString];
	
		if (dateArray == nil)
		{
			dateArray = [NSMutableArray array];
			[allDates setValue:dateArray forKey:dateString];
			
			[dateStrings addObject:dateString];
		}
		
		[dateArray addObject:event];
		
		NSString * source = [event valueForKey:@"source"];
		
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
