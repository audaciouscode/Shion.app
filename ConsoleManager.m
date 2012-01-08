//
//  ConsoleManager.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Shion/ASPowerLinc2412Controller.h>

#import "NSDictionary+BSJSONAdditions.h"
#import "NSScanner+BSJSONAdditions.h"

#import "ConsoleManager.h"

#import "DeviceManager.h"
#import "SnapshotManager.h"
#import "TriggerManager.h"
#import "EventManager.h"
#import "PreferencesManager.h"

#import "Appliance.h"
#import "Lamp.h"
#import "Thermostat.h"
#import "Chime.h"
#import "House.h"
#import "Controller.h"
#import "MotionSensor.h"
#import "ApertureSensor.h"
#import "PowerSensor.h"
#import "Phone.h"
#import "MobileClient.h"
#import "Camera.h"
#import "RokuDVP.h"
#import "Tivo.h"
#import "PowerMeterSensor.h"
#import "Lock.h"
#import "WeatherUndergroundStation.h"
#import "GarageHawk.h"

#import "Snapshot.h"
#import "Trigger.h"
#import "ShionTriggerPopUpButton.h"

#import "Shion.h"

#define CAN_EDIT @"can_edit"
#define ALL_LOCATIONS @"all_locations"
#define ALL_CATEGORIES @"all_categories"
#define CURRENT_MAIN_TAB @"current_main_tab"
#define CURRENT_INFO_TAB @"current_info_tab"

#define LOCATION_EDITABLE @"location_editable"

#define LABEL @"label"

@implementation ConsoleManager

static ConsoleManager * sharedInstance = nil;

+ (ConsoleManager *) sharedInstance
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

#pragma mark -
#pragma mark Standard Class Methods

- (id) init
{
	if (self = [super init])
	{
		windowController = [[NSWindowController alloc] initWithWindowNibName:@"ConsoleWindow" owner:self];
		treeIndex = nil;
	}
	
	return self;
}

- (void) awakeFromNib
{
	[browser setDoubleAction:@selector(edit:)];
	[browser setTarget:self];
	
	[treeController addObserver:self forKeyPath:@"selection" options:0 context:NULL];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestSnapshot:) name:NEED_SNAPSHOT object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestScript:) name:NEED_SCRIPT object:nil];
	
	NSNumber * showTips = [[NSUserDefaults standardUserDefaults] valueForKey:@"show_tips"];
	
	if (showTips == nil || [showTips boolValue])
		[self showTips:self];
}

- (NSArray *) fetchTips
{
	NSString * path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Tips"] 
					   stringByAppendingPathComponent:@"Shion Tips.plist"];
	
	return [NSArray arrayWithContentsOfFile:path];
}

- (IBAction) showTips:(id) sender
{
	NSArray * tips = [self fetchTips];
	
	NSNumber * tipIndex = [[NSUserDefaults standardUserDefaults] valueForKey:@"next_tip"];
	
	if (tipIndex == nil)
		tipIndex = [NSNumber numberWithInt:0];
	else if ([tipIndex intValue] >= [tips count])
		tipIndex = [NSNumber numberWithInt:0];

	NSDictionary * tip = [tips objectAtIndex:[tipIndex unsignedIntValue]];
	
	NSString * imagePath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Tips"] stringByAppendingPathComponent:[tip valueForKey:@"image"]];
	
	NSImage * image = [[NSImage alloc] initByReferencingFile:imagePath];
	
	[tipImageView setImage:image];
	[tipText setStringValue:[tip valueForKey:@"description"]];
	
	if (![tipWindow isVisible])
		[tipWindow center];
	
	[tipWindow makeKeyAndOrderFront:sender];
	
	[image release];

	[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:([tipIndex unsignedIntValue] + 1)] forKey:@"next_tip"];
}

- (IBAction) nextTip:(id) sender
{
	[self showTips:sender];
}

- (IBAction) closeTips:(id) sender
{
	[tipWindow orderOut:sender];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"selection"])
	{
		[self willChangeValueForKey:CAN_EDIT];
		[self didChangeValueForKey:CAN_EDIT];

		[self willChangeValueForKey:CURRENT_MAIN_TAB];
		[self didChangeValueForKey:CURRENT_MAIN_TAB];

		[self willChangeValueForKey:CURRENT_INFO_TAB];
		[self didChangeValueForKey:CURRENT_INFO_TAB];
	}
}

- (void) didChangeValueForKey:(NSString *) key
{
	[super didChangeValueForKey:key];

	if ([key isEqual:NAV_TREE])
	{
		if (treeIndex != nil)
		{
			[treeController setSelectionIndexPath:treeIndex];
			[treeIndex release];
			treeIndex = nil;
		}
	}
}

- (void) willChangeValueForKey:(NSString *) key
{
	if ([key isEqual:NAV_TREE])
	{
		NSIndexPath * path = [treeController selectionIndexPath];
		
		if (treeIndex != nil)
		{
			[treeIndex release];
			treeIndex = nil;
		}
		
		if (path != nil)
			treeIndex = [path retain];
	}

	[super willChangeValueForKey:key];
}

- (NSArray *) deviceTree
{
	NSMutableArray * devices = [NSMutableArray array];
	
	NSMutableDictionary * allDevices = [NSMutableDictionary dictionaryWithObject:@"All Devices" forKey:@"label"];
	NSMutableArray * allDevicesArray = [NSMutableArray array];
	[allDevices setValue:allDevicesArray forKey:@"children"];
	
	NSMutableDictionary * locations = [NSMutableDictionary dictionary];
	NSMutableDictionary * types = [NSMutableDictionary dictionary];
	NSMutableDictionary * platforms = [NSMutableDictionary dictionary];
	
	NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * device = nil;
	while (device = [deviceIter nextObject])
	{
		NSMutableDictionary * deviceDict = [NSMutableDictionary dictionary];
		[deviceDict setValue:device forKey:DEVICE];
		[deviceDict setValue:[device name] forKey:LABEL];
		
		if (![allDevicesArray containsObject:deviceDict])
			[allDevicesArray addObject:deviceDict];
		
		NSMutableArray * location = [locations valueForKey:[device location]];
		
		if (location == nil)
		{
			location = [NSMutableArray array];
			[locations setValue:location forKey:[device location]];
		}
		
		if (![location containsObject:device])
			[location addObject:device];

		NSMutableArray * type = [types valueForKey:[device type]];
		
		if (type == nil)
		{
			type = [NSMutableArray array];
			[types setValue:type forKey:[device type]];
		}
		
		if (![type containsObject:device])
			[type addObject:device];

		NSMutableArray * platform = [platforms valueForKey:[device platform]];
		
		if (platform == nil)
		{
			platform = [NSMutableArray array];
			[platforms setValue:platform forKey:[device platform]];
		}
		
		if (![platform containsObject:device])
			[platform addObject:device];
	}
	
	[devices addObject:allDevices];
	
	if ([[locations allKeys] count] > 1)
	{
		NSMutableDictionary * byLocation = [NSMutableDictionary dictionaryWithObject:@"By Location" forKey:@"label"];
		NSMutableArray * locationArray = [NSMutableArray array];
		[byLocation setValue:locationArray forKey:@"children"];

		NSEnumerator * locationIter = [[[locations allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
		NSString * location = nil;
		while (location = [locationIter nextObject])
		{
			NSMutableDictionary * locationDict = [NSMutableDictionary dictionaryWithObject:location forKey:@"label"];
			NSMutableArray * deviceArray = [NSMutableArray array];
		
			NSEnumerator * deviceIter = [[locations valueForKey:location] objectEnumerator];
			Device * device = nil;
			while (device = [deviceIter nextObject])
			{
				NSMutableDictionary * deviceDict = [NSMutableDictionary dictionary];
				[deviceDict setValue:device forKey:DEVICE];
				[deviceDict setValue:[device name] forKey:LABEL];
			
				[deviceArray addObject:deviceDict];
			}			
			
			[locationDict setValue:deviceArray forKey:@"children"];
			[locationArray addObject:locationDict];
		}
		
		[devices addObject:byLocation];
	}
	
	NSMutableDictionary * byType = [NSMutableDictionary dictionaryWithObject:@"By Type" forKey:@"label"];
	NSMutableArray * typeArray = [NSMutableArray array];
	[byType setValue:typeArray forKey:@"children"];
	
	NSEnumerator * typeIter = [[[types allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
	NSString * type = nil;
	while (type = [typeIter nextObject])
	{
		NSMutableDictionary * typeDict = [NSMutableDictionary dictionaryWithObject:type forKey:@"label"];
		NSMutableArray * deviceArray = [NSMutableArray array];
		
		NSEnumerator * deviceIter = [[types valueForKey:type] objectEnumerator];
		Device * device = nil;
		while (device = [deviceIter nextObject])
		{
			NSMutableDictionary * deviceDict = [NSMutableDictionary dictionary];
			[deviceDict setValue:device forKey:DEVICE];
			[deviceDict setValue:[device name] forKey:LABEL];
			
			[deviceArray addObject:deviceDict];
		}			
		
		[typeDict setValue:deviceArray forKey:@"children"];
		[typeArray addObject:typeDict];
	}

	[devices addObject:byType];

	if ([[platforms allKeys] count] > 1)
	{
		NSMutableDictionary * byPlatform = [NSMutableDictionary dictionaryWithObject:@"By Platform" forKey:@"label"];
		NSMutableArray * platformArray = [NSMutableArray array];
		[byPlatform setValue:platformArray forKey:@"children"];
	
		NSEnumerator * platformIter = [[[platforms allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
		NSString * platform = nil;
		while (platform = [platformIter nextObject])
		{
			NSMutableDictionary * platformDict = [NSMutableDictionary dictionaryWithObject:platform forKey:@"label"];
			NSMutableArray * deviceArray = [NSMutableArray array];
		
			NSEnumerator * deviceIter = [[platforms valueForKey:platform] objectEnumerator];
			Device * device = nil;
			while (device = [deviceIter nextObject])
			{
				NSMutableDictionary * deviceDict = [NSMutableDictionary dictionary];
				[deviceDict setValue:device forKey:DEVICE];
				[deviceDict setValue:[device name] forKey:LABEL];
			
				[deviceArray addObject:deviceDict];
			}			
		
			[platformDict setValue:deviceArray forKey:@"children"];
			[platformArray addObject:platformDict];
		}
	
		[devices addObject:byPlatform];
	}
	
	return devices;
}

- (NSArray *) snapshotTree
{
	NSMutableArray * snapshotTree = [NSMutableArray array];
	
	NSMutableDictionary * allSnapshots = [NSMutableDictionary dictionaryWithObject:@"All Snapshots" forKey:@"label"];
	NSMutableArray * allSnapshotsArray = [NSMutableArray array];
	[allSnapshots setValue:allSnapshotsArray forKey:@"children"];

	NSMutableDictionary * categories = [NSMutableDictionary dictionary];
	
	NSEnumerator * snapIter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
	Snapshot * snapshot = nil;
	while (snapshot = [snapIter nextObject])
	{
		NSMutableDictionary * snapDict = [NSMutableDictionary dictionary];
		[snapDict setValue:snapshot forKey:SNAPSHOT];
		[snapDict setValue:[snapshot name] forKey:LABEL];
		
		if (![allSnapshotsArray containsObject:snapDict])
			[allSnapshotsArray addObject:snapDict];
		
		NSMutableArray * category = [categories valueForKey:[snapshot category]];
		
		if (category == nil)
		{
			category = [NSMutableArray array];
			[categories setValue:category forKey:[snapshot category]];
		}
		
		if (![category containsObject:snapshot])
			[category addObject:snapshot];
	}

	NSMutableDictionary * byCategory = [NSMutableDictionary dictionaryWithObject:@"By Category" forKey:@"label"];
	NSMutableArray * categoryArray = [NSMutableArray array];
	[byCategory setValue:categoryArray forKey:@"children"];
	
	NSEnumerator * categoryIter = [[[categories allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
	NSString * category = nil;
	while (category = [categoryIter nextObject])
	{
		NSMutableDictionary * categoryDict = [NSMutableDictionary dictionaryWithObject:category forKey:@"label"];
		NSMutableArray * snapArray = [NSMutableArray array];
		
		NSEnumerator * snapIter = [[categories valueForKey:category] objectEnumerator];
		Snapshot * snapshot = nil;
		while (snapshot = [snapIter nextObject])
		{
			NSMutableDictionary * snapDict = [NSMutableDictionary dictionary];
			[snapDict setValue:snapshot forKey:SNAPSHOT];
			[snapDict setValue:[snapshot name] forKey:LABEL];
			
			[snapArray addObject:snapDict];
		}			
		
		[categoryDict setValue:snapArray forKey:@"children"];
		[categoryArray addObject:categoryDict];
	}

	[snapshotTree addObject:allSnapshots];
	[snapshotTree addObject:byCategory];

	return snapshotTree;
}

- (NSArray *) triggerTree
{
	NSMutableArray * triggers = [NSMutableArray array];
	
	NSMutableDictionary * allTriggers = [NSMutableDictionary dictionaryWithObject:@"All Triggers" forKey:@"label"];
	NSMutableArray * allTriggersArray = [NSMutableArray array];
	[allTriggers setValue:allTriggersArray forKey:@"children"];
	
	NSMutableDictionary * types = [NSMutableDictionary dictionary];
	NSMutableDictionary * actions = [NSMutableDictionary dictionary];
	
	NSEnumerator * triggerIter = [[[TriggerManager sharedInstance] triggers] objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [triggerIter nextObject])
	{
		NSMutableDictionary * triggerDict = [NSMutableDictionary dictionary];
		[triggerDict setValue:trigger forKey:TRIGGER];
		
		if ([trigger name] == nil)
			[trigger setValue:@"New Trigger" forKey:TRIGGER_NAME];
		
		[triggerDict setValue:[trigger name] forKey:LABEL];
		
		if (![allTriggersArray containsObject:triggerDict])
			[allTriggersArray addObject:triggerDict];
		
		NSMutableArray * triggerType = [types valueForKey:[trigger type]];
		
		if (triggerType == nil)
		{
			triggerType = [NSMutableArray array];
			[types setValue:triggerType forKey:[trigger type]];
		}
		
		if (![triggerType containsObject:trigger])
			[triggerType addObject:trigger];

		NSMutableArray * triggerAction = [actions valueForKey:[trigger action]];
		
		if (triggerAction == nil)
		{
			triggerAction = [NSMutableArray array];
			[actions setValue:triggerAction forKey:[trigger action]];
		}
		
		if (![triggerAction containsObject:trigger])
			[triggerAction addObject:trigger];
	}
	
	NSMutableDictionary * byType = [NSMutableDictionary dictionaryWithObject:@"By Type" forKey:@"label"];
	NSMutableArray * typesArray = [NSMutableArray array];
	[byType setValue:typesArray forKey:@"children"];

	NSEnumerator * typeIter = [[[types allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
	NSString * type = nil;
	while (type = [typeIter nextObject])
	{
		NSMutableDictionary * typeDict = [NSMutableDictionary dictionaryWithObject:type forKey:@"label"];
		NSMutableArray * typeArray = [NSMutableArray array];
		
		NSEnumerator * triggerIter = [[types valueForKey:type] objectEnumerator];
		Trigger * trigger = nil;
		while (trigger = [triggerIter nextObject])
		{
			NSMutableDictionary * triggerDict = [NSMutableDictionary dictionary];
			[triggerDict setValue:trigger forKey:TRIGGER];
			[triggerDict setValue:[trigger name] forKey:LABEL];
			
			[typeArray addObject:triggerDict];
		}			
		
		[typeDict setValue:typeArray forKey:@"children"];
		[typesArray addObject:typeDict];
	}

	NSMutableDictionary * byAction = [NSMutableDictionary dictionaryWithObject:@"By Action" forKey:@"label"];
	NSMutableArray * actionsArray = [NSMutableArray array];
	[byAction setValue:actionsArray forKey:@"children"];
	
	NSEnumerator * actionIter = [[[actions allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectEnumerator];
	NSString * action = nil;
	while (action = [actionIter nextObject])
	{
		NSMutableDictionary * actionDict = [NSMutableDictionary dictionaryWithObject:action forKey:@"label"];
		NSMutableArray * actionArray = [NSMutableArray array];
		
		NSEnumerator * triggerIter = [[actions valueForKey:action] objectEnumerator];
		Trigger * trigger = nil;
		while (trigger = [triggerIter nextObject])
		{
			NSMutableDictionary * triggerDict = [NSMutableDictionary dictionary];
			[triggerDict setValue:trigger forKey:TRIGGER];
			[triggerDict setValue:[trigger name] forKey:LABEL];
			
			[actionArray addObject:triggerDict];
		}			
		
		[actionDict setValue:actionArray forKey:@"children"];
		[actionsArray addObject:actionDict];
	}
	
	[triggers addObject:allTriggers];
	[triggers addObject:byType];
	[triggers addObject:byAction];
	
	return triggers;
}

- (NSArray *) favoritesTree
{
	NSMutableArray * allItems = [NSMutableArray arrayWithArray:[[DeviceManager sharedInstance] devices]];
	[allItems addObjectsFromArray:[[SnapshotManager sharedInstance] snapshots]];
	[allItems addObjectsFromArray:[[TriggerManager sharedInstance] triggers]];
	
	NSMutableArray * favorites = [NSMutableArray array];
	
	NSEnumerator * itemIter = [allItems objectEnumerator];
	NSDictionary * item = nil;
	while (item = [itemIter nextObject])
	{
		if ([[item valueForKey:@"favorite"] boolValue])
		{
			NSMutableDictionary * dict = [NSMutableDictionary dictionary];
			[dict setValue:[item valueForKey:@"name"] forKey:LABEL];

			if ([item isKindOfClass:[Device class]])
				[dict setValue:item forKey:DEVICE];
			else if ([item isKindOfClass:[Trigger class]])
				[dict setValue:item forKey:TRIGGER];
			else if ([item isKindOfClass:[Snapshot class]])
				[dict setValue:item forKey:SNAPSHOT];
			
			[favorites addObject:dict];
		}
	}
	
	return favorites;
}

- (id) valueForKey:(NSString *) key
{
	if ([key isEqual:NAV_TREE])
	{
		// TODO: Move these items to their respective managers?
		
		NSMutableArray * children = [NSMutableArray array];
		
		NSMutableDictionary * allDevices = [NSMutableDictionary dictionaryWithObject:@"Devices" forKey:@"label"];
		[allDevices setValue:[self deviceTree] forKey:@"children"];

		NSMutableDictionary * snapshotTree = [NSMutableDictionary dictionaryWithObject:@"Snapshots" forKey:@"label"];
		[snapshotTree setValue:[self snapshotTree] forKey:@"children"];

		NSMutableDictionary * triggers = [NSMutableDictionary dictionaryWithObject:@"Triggers" forKey:@"label"];
		[triggers setValue:[self triggerTree] forKey:@"children"];

		NSMutableDictionary * events = [NSMutableDictionary dictionaryWithObject:@"Events" forKey:@"label"];
		[events setValue:[[EventManager sharedInstance] eventsTree] forKey:@"children"];
		[events setValue:[[EventManager sharedInstance] events] forKey:EVENT_LIST];

		NSMutableDictionary * favorites = [NSMutableDictionary dictionaryWithObject:@"Favorites" forKey:@"label"];
		[favorites setValue:[self favoritesTree] forKey:@"children"];

		[children addObject:favorites];
		[children addObject:allDevices];
		[children addObject:snapshotTree];
		[children addObject:triggers];
		[children addObject:events];
		
		return children;
	}
	else if ([key isEqual:CAN_EDIT])
	{
		NSDictionary * selection = [[treeController selectedObjects] lastObject];
		
		if ([[selection valueForKey:DEVICE] isKindOfClass:[Device class]])
		{
			if ([[selection valueForKey:DEVICE] isKindOfClass:[Phone class]])
				return [NSNumber numberWithBool:NO];

			return [NSNumber numberWithBool:YES];

		}
		else if ([[selection valueForKey:SNAPSHOT] isKindOfClass:[Snapshot class]])
			return [NSNumber numberWithBool:YES];
		else if ([[selection valueForKey:TRIGGER] isKindOfClass:[Trigger class]])
			return [NSNumber numberWithBool:YES];

		return [NSNumber numberWithBool:NO];
	}
	else if ([key isEqual:ALL_LOCATIONS])
	{
		NSMutableSet * locations = [NSMutableSet set];
		
		NSEnumerator * deviceIter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		Device * device = nil;
		while (device = [deviceIter nextObject])
		{
			NSString * location = [device location];
			
			if (location)
				[locations addObject:location];
		}

		return [[locations allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	}
	else if ([key isEqual:ALL_CATEGORIES])
	{
		NSMutableSet * categories = [NSMutableSet set];
		
		NSEnumerator * snapIter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
		Snapshot * snapshot = nil;
		while (snapshot = [snapIter nextObject])
		{
			NSString * category = [snapshot category];
			
			if (category)
				[categories addObject:category];
		}
		
		return [[categories allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	}
	else if ([key isEqual:CURRENT_MAIN_TAB])
	{
		NSDictionary * device = [[[treeController selectedObjects] lastObject] valueForKey:DEVICE];
		NSDictionary * snapshot = [[[treeController selectedObjects] lastObject] valueForKey:SNAPSHOT];
		NSDictionary * trigger = [[[treeController selectedObjects] lastObject] valueForKey:TRIGGER];
		NSDictionary * events = [[[treeController selectedObjects] lastObject] valueForKey:EVENT_LIST];
		
		if ([device isKindOfClass:[Device class]])
		{
			if ([device isKindOfClass:[Lamp class]])
			{
				if ([[((Device *) device) platform] isEqual:@"X10"])
					return @"X10 Lamp";
				else
					return @"Lamp";
			}
			else if ([device isKindOfClass:[Appliance class]])
				return @"Appliance";
			else if ([device isKindOfClass:[Thermostat class]])
				return @"Thermostat";
			else if ([device isKindOfClass:[Chime class]])
				return @"Chime";
			else if ([device isKindOfClass:[House class]])
				return @"House";
			else if ([device isKindOfClass:[MotionSensor class]])
				return @"Motion Sensor";
			else if ([device isKindOfClass:[ApertureSensor class]])
				return @"Aperture Sensor";
			else if ([device isKindOfClass:[PowerSensor class]])
				return @"Power Sensor";
			else if ([device isKindOfClass:[Controller class]])
			{
				Controller * controller = (Controller *) device;
				
				if ([[controller deviceController] isKindOfClass:[ASPowerLinc2412Controller class]])
					return @"Insteon Serial Controller";
				
				return @"Controller";
			}
			else if ([device isKindOfClass:[House class]])
				return @"House";
			else if ([device isKindOfClass:[MobileClient class]])
				return @"Mobile Device";
			else if ([device isKindOfClass:[Camera class]])
				return @"Camera";
			else if ([device isKindOfClass:[Phone class]])
				return @"Modem";
			else if ([device isKindOfClass:[RokuDVP class]])
				return @"Roku";
			else if ([device isKindOfClass:[Tivo class]])
				return @"Tivo";
			else if ([device isKindOfClass:[WeatherUndergroundStation class]])
				return @"Weather Station";
			else if ([device isKindOfClass:[PowerMeterSensor class]])
				return @"Power Meter Sensor";
			else if ([device isKindOfClass:[Lock class]])
				return @"Lock";
			else if ([device isKindOfClass:[GarageHawk class]])
				return @"GarageHawk";
			
			// TODO: Other types..
		}
		else if (snapshot != nil)
			return @"Snapshot";
		else if (events != nil)
			return @"Event List";
		else if (trigger != nil)
			return @"Trigger";
			
		return @"Default";
	}
	else if ([key isEqual:CURRENT_INFO_TAB])
	{
		NSDictionary * selection = [[treeController selectedObjects] lastObject];
		
		if ([selection valueForKey:DEVICE])
			return @"Device";
		else if ([selection valueForKey:SNAPSHOT])
			return @"Snapshot";
		else if ([selection valueForKey:TRIGGER])
			return @"Trigger";
			
		return @"Default";
	}
	else if ([key isEqual:LOCATION_EDITABLE])
	{
		NSDictionary * device = [[[treeController selectedObjects] lastObject] valueForKey:DEVICE];
		
		if ([device isKindOfClass:[Device class]])
		{
			if ([device isKindOfClass:[Controller class]])
				return [NSNumber numberWithBool:NO];
				
			return [NSNumber numberWithBool:YES];
		}
		
	}
	else if ([key isEqual:@"computer_location"])
	{
		PreferencesManager * pm = [PreferencesManager sharedInstance];
		
		NSNumber * lat = [pm valueForKey:@"site_latitude"];
		NSNumber * lon = [pm valueForKey:@"site_longitude"];
		
		if (lat == nil || lon == nil)
		{
			MachineLocation * location =  malloc (sizeof (MachineLocation));
		
			ReadLocation (location);
		
			float latitude = 90 * FractToFloat (location->latitude);
			float longitude = -90 * FractToFloat (location->longitude);

			[pm setValue:[NSNumber numberWithFloat:latitude] forKey:@"site_latitude"];
			[pm setValue:[NSNumber numberWithFloat:longitude] forKey:@"site_longitude"];
			
			free (location);
			
			return [self valueForKey:@"computer_location"];
		}

		return [NSString stringWithFormat:@"%f, %f", [lat doubleValue], [lon doubleValue]];
	}
	else if ([key isEqual:@"motion_sensors"])
	{
		NSMutableArray * motionSensors = [NSMutableArray array];
		
		NSEnumerator * iter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		Device * device = nil;
		while (device = [iter nextObject])
		{
			if ([device isKindOfClass:[MotionSensor class]] && ![motionSensors containsObject:[device name]])
				[motionSensors addObject:[device name]];
		}
		
		[motionSensors sortUsingSelector:@selector(caseInsensitiveCompare:)];
		
		return motionSensors;
	}
	else if ([key isEqual:@"aperture_sensors"])
	{
		NSMutableArray * apertureSensors = [NSMutableArray array];
		
		NSEnumerator * iter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		Device * device = nil;
		while (device = [iter nextObject])
		{
			if ([device isKindOfClass:[ApertureSensor class]] && ![apertureSensors containsObject:[device name]])
				[apertureSensors addObject:[device name]];
		}
		
		[apertureSensors sortUsingSelector:@selector(caseInsensitiveCompare:)];
		
		return apertureSensors;
	}
	else if ([key isEqual:@"mobile_device_names"])
	{
		NSMutableArray * deviceNames = [NSMutableArray array];
		
		NSEnumerator * iter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
		Device * device = nil;
		while (device = [iter nextObject])
		{
			NSString * deviceString = [NSString stringWithFormat:@"%@ (%@)", [device name], [device identifier]];
			
			if ([device isKindOfClass:[MobileClient class]] && ![deviceNames containsObject:deviceString])
				[deviceNames addObject:deviceString];
		}
		
		[deviceNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
		
		return deviceNames;
	}
	else if ([key isEqual:@"snapshots"])
		return [[SnapshotManager sharedInstance] snapshots];
	else if ([key isEqual:@"phoneCallArray"])
	{
		NSMutableArray * array = [NSMutableArray array];
		
		NSArray * events = [[EventManager sharedInstance] eventsForIdentifier:@"Phone"];
		
		NSEnumerator * iter = [events objectEnumerator];
		NSManagedObject * event = nil;
		while (event = [iter nextObject])
		{
			NSDictionary * callDict = [NSDictionary dictionaryWithJSONString:[event valueForKey:@"value"]];
			
			NSMutableDictionary * call = [NSMutableDictionary dictionary];
			[call setValue:[callDict valueForKey:@"caller_name"] forKey:@"caller"];
			[call setValue:[callDict valueForKey:@"number"] forKey:@"number"];
			[call setValue:[event valueForKey:@"date"] forKey:@"date"];
			
			[array addObject:call];
		}
		
		/*
		 NSString * desc = [NSString stringWithFormat:@"Received phone call from %@ (%@).", [call valueForKey:@"caller_name"], 
		 [call valueForKey:@"number"]];
		 
		 [[EventManager sharedInstance] createEvent:@"device" source:@"Phone" initiator:@"Phone"
		 description:desc
		 value:call];
		 */	 
		
		return array;
	}		
		
		
	return nil;
}

- (void) setValue:(id) value forKey:(NSString *) key
{

}

- (IBAction) consoleWindow:(id) sender
{
	[NSApp activateIgnoringOtherApps:YES];
	
	[windowController showWindow:sender];
	
	[window makeKeyAndOrderFront:sender];
	
	if ([tipWindow isVisible])
		[tipWindow makeKeyAndOrderFront:sender];
}

- (IBAction) showAddMenu:(id) sender
{
	NSPopUpButtonCell * cell = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
	[cell setMenu:[sender menu]];
	[cell performClickWithFrame:NSMakeRect(0, 0, 0, 0) inView:sender];
	[cell release];
}

- (NSIndexPath *) indexPathForObject:(NSDictionary *) object tree:(id) tree
{
	for (unsigned int i = 0; i < [tree count]; i++)
	{
		NSDictionary * node = [tree objectAtIndex:i];
		
		if ([[node valueForKey:DEVICE] isEqualToDictionary:object])
			return [NSIndexPath indexPathWithIndex:i];
		else if ([[node valueForKey:SNAPSHOT] isEqualToDictionary:object])
			return [NSIndexPath indexPathWithIndex:i];
		else if ([[node valueForKey:TRIGGER] isEqualToDictionary:object])
			return [NSIndexPath indexPathWithIndex:i];
		else 
		{
			NSIndexPath * indexPath = [self indexPathForObject:object tree:[node valueForKey:@"children"]];
			
			if (indexPath != nil)
			{
				NSIndexPath * thisPath = [NSIndexPath indexPathWithIndex:i];
				
				for (unsigned int j = 0; j < [indexPath length]; j++)
					thisPath = [thisPath indexPathByAddingIndex:[indexPath indexAtPosition:j]];
				
				return thisPath;
			}			
		}
	}
	
	return nil;
}

- (NSIndexPath *) indexPathForObjectWithIdentifier:(NSString *) identifier tree:(id) tree
{
	for (unsigned int i = 0; i < [tree count]; i++)
	{
		NSDictionary * node = [tree objectAtIndex:i];

		id object = [node valueForKey:DEVICE];

		if (object == nil)
			object = [node valueForKey:SNAPSHOT];

		if (object == nil)
			object = [node valueForKey:TRIGGER];

		
		if (object != nil && [[object identifier] isEqual:identifier])
			return [NSIndexPath indexPathWithIndex:i];
		else 
		{
			NSIndexPath * indexPath = [self indexPathForObjectWithIdentifier:identifier tree:[node valueForKey:@"children"]];
			
			if (indexPath != nil)
			{
				NSIndexPath * thisPath = [NSIndexPath indexPathWithIndex:i];
				
				for (unsigned int j = 0; j < [indexPath length]; j++)
					thisPath = [thisPath indexPathByAddingIndex:[indexPath indexAtPosition:j]];
				
				return thisPath;
			}			
		}
	}
	
	return nil;
}


- (void) selectItemWithIdentifier:(NSString *) identifier
{
	NSIndexPath * indexPath = [self indexPathForObjectWithIdentifier:identifier tree:[treeController selectedObjects]];
	
	if (indexPath == nil)
		indexPath = [self indexPathForObjectWithIdentifier:identifier tree:[treeController content]];
	else
	{
		NSIndexPath * selection = [treeController selectionIndexPath];
		
		for (unsigned int i = 1; i < [indexPath length]; i++)
			selection = [selection indexPathByAddingIndex:[indexPath indexAtPosition:i]];
			
		indexPath = selection;
	}
	
	[treeController setSelectionIndexPath:indexPath];
}

- (IBAction) addDevice:(id) sender
{
	NSMenuItem * menuItem = (NSMenuItem *) sender;
	
	NSString * deviceType = [menuItem title];
	
	NSString * platform = [[menuItem menu] title];

	Device * device = [[DeviceManager sharedInstance] createDevice:deviceType platform:platform];

	[self willChangeValueForKey:NAV_TREE]; //  withSetMutation:NSKeyValueSetSetMutation usingObjects:[self valueForKey:NAV_TREE]];

	[treeController setSelectionIndexPath:nil];

	[self didChangeValueForKey:NAV_TREE]; // withSetMutation:NSKeyValueSetSetMutation usingObjects:[self valueForKey:NAV_TREE]];

	NSIndexPath * indexPath = [self indexPathForObject:device tree:[treeController content]];

	[treeController setSelectionIndexPath:indexPath];

	[self edit:sender];
}

- (IBAction) addSnapshot:(id) sender
{
	[self willChangeValueForKey:@"snapshots"];
	
	Snapshot * snapshot = [[SnapshotManager sharedInstance] createSnapshot];

	[treeController setSelectionIndexPath:nil];
	
	[self willChangeValueForKey:NAV_TREE]; //  withSetMutation:NSKeyValueSetSetMutation usingObjects:[self valueForKey:NAV_TREE]];
	
	[self didChangeValueForKey:NAV_TREE]; //  withSetMutation:NSKeyValueSetSetMutation usingObjects:[self valueForKey:NAV_TREE]];
	
	NSIndexPath * indexPath = [self indexPathForObject:snapshot tree:[treeController content]];
	
	[treeController setSelectionIndexPath:indexPath];
	
	[self edit:sender];

	[self didChangeValueForKey:@"snapshots"];
}

- (IBAction) dismissSnapshotEditor:(id) sender
{
	[self reloadDevices];

	[self willChangeValueForKey:ALL_CATEGORIES];
	
	[NSApp endSheet:addSnapshotPanel];
	[addSnapshotPanel orderOut:self];
	
	[self didChangeValueForKey:ALL_CATEGORIES];
}

- (IBAction) edit:(id) sender
{
	if ([[self valueForKey:CAN_EDIT] boolValue])
	{
		NSDictionary * selection = [[treeController selectedObjects] lastObject];
		
		if ([selection valueForKey:DEVICE])
		{
			Device * device = [selection valueForKey:DEVICE];
			
			if ([device isKindOfClass:[Controller class]])
				[[PreferencesManager sharedInstance] showControllerDetails];
			else if ([device isKindOfClass:[Camera class]])
				[NSApp beginSheet:addCameraPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:NULL];
			else
				[NSApp beginSheet:addDevicePanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:NULL];
		}
		else if ([selection valueForKey:SNAPSHOT])
			[NSApp beginSheet:addSnapshotPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:NULL];
		else if ([selection valueForKey:TRIGGER])
			[NSApp beginSheet:addTriggerPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:NULL];
	}
}

- (IBAction) beacon:(id) sender
{
	NSDictionary * selection = [[treeController selectedObjects] lastObject];

	Device * device = [selection valueForKey:DEVICE];
	
	if ([device isKindOfClass:[MobileClient class]])
	{
		MobileClient * mobile = (MobileClient *) device;
		
		[mobile beacon];
	}
}

- (IBAction) remove:(id) sender
{
	NSDictionary * selection = [[treeController selectedObjects] lastObject];
	
	NSIndexPath * selectionPath = [treeController selectionIndexPath];
	
	if ([[selection valueForKey:DEVICE] isKindOfClass:[Device class]])
	{
		[[DeviceManager sharedInstance] removeDevice:((Device *) [selection valueForKey:DEVICE])];
//		selectionPath = [selectionPath indexPathByRemovingLastIndex];
	}
	else if ([[selection valueForKey:SNAPSHOT] isKindOfClass:[Snapshot class]])
	{
		[[SnapshotManager sharedInstance] removeSnapshot:((Snapshot *) [selection valueForKey:SNAPSHOT])];
//		selectionPath = [selectionPath indexPathByRemovingLastIndex];
	}
	else if ([[selection valueForKey:TRIGGER] isKindOfClass:[Trigger class]])
	{
		[[TriggerManager sharedInstance] removeTrigger:((Trigger *) [selection valueForKey:TRIGGER])];
//		selectionPath = [selectionPath indexPathByRemovingLastIndex];
	}
	else
	{
		NSRunAlertPanel(@"Debug: Unable to remove node", @"Cannot remove node.", @"OK", nil, nil);
	}
	
	[treeController setSelectionIndexPath:nil];

	[self willChangeValueForKey:NAV_TREE withSetMutation:NSKeyValueSetSetMutation usingObjects:[self valueForKey:NAV_TREE]];
	
	[self didChangeValueForKey:NAV_TREE withSetMutation:NSKeyValueSetSetMutation usingObjects:[self valueForKey:NAV_TREE]];

	[treeController setSelectionIndexPath:selectionPath];
}

- (IBAction) dismissDeviceEditor:(id) sender
{
	[self reloadDevices];
	
	[self willChangeValueForKey:ALL_LOCATIONS];
	
	[NSApp endSheet:addDevicePanel];
	[addDevicePanel orderOut:self];

	[self didChangeValueForKey:ALL_LOCATIONS];
}

- (IBAction) dismissCameraEditor:(id) sender
{
	[self reloadDevices];
	
	[self willChangeValueForKey:ALL_LOCATIONS];
	
	[NSApp endSheet:addCameraPanel];
	[addCameraPanel orderOut:self];
	
	[self didChangeValueForKey:ALL_LOCATIONS];
}

- (IBAction) addTrigger:(id) sender
{
	NSMenuItem * menuItem = (NSMenuItem *) sender;
	
	NSString * triggerType = [menuItem title];
	
	Trigger * trigger = [[TriggerManager sharedInstance] createTrigger:triggerType];

	[treeController setSelectionIndexPath:nil];

	[self willChangeValueForKey:NAV_TREE withSetMutation:NSKeyValueSetSetMutation usingObjects:[self valueForKey:NAV_TREE]];
	
	[self didChangeValueForKey:NAV_TREE withSetMutation:NSKeyValueSetSetMutation usingObjects:[self valueForKey:NAV_TREE]];
	
	NSIndexPath * indexPath = [self indexPathForObject:trigger tree:[treeController content]];
	
	[treeController setSelectionIndexPath:indexPath];
	
	[self edit:sender];
}

- (IBAction) dismissTriggerEditor:(id) sender
{
	[self reloadDevices];
	
	[self willChangeValueForKey:ALL_CATEGORIES];
	
	[NSApp endSheet:addTriggerPanel];
	[addTriggerPanel orderOut:self];
	
	[self didChangeValueForKey:ALL_CATEGORIES];
}

- (IBAction) dismissSnapshotsPanel:(id) sender
{
	NSDictionary * selection = [[treeController selectedObjects] lastObject];
	
	if ([selection valueForKey:TRIGGER])
	{
		Trigger * trigger = [selection valueForKey:TRIGGER];

		Snapshot * selected = [[snapshots selectedObjects] lastObject];
		
		[trigger setValue:[selected identifier] forKey:@"snapshot"];
	}
	
	[NSApp endSheet:snapshotsPanel];
	[snapshotsPanel orderOut:self];
}

- (void) reloadDevices
{
	NSDictionary * selection = nil;
	
	if (treeController != nil)
		selection = [[treeController selectedObjects] lastObject];

	[treeController setSelectionIndexPath:nil];
	
	[self willChangeValueForKey:NAV_TREE];

	[self didChangeValueForKey:NAV_TREE];

	if (selection != nil)
	{
		NSIndexPath * indexPath = [self indexPathForObject:[selection valueForKey:DEVICE] tree:[treeController content]];

		if (indexPath == nil)
			indexPath = [self indexPathForObject:[selection valueForKey:SNAPSHOT] tree:[treeController content]];

		if (indexPath == nil)
			indexPath = [self indexPathForObject:[selection valueForKey:TRIGGER] tree:[treeController content]];

		[treeController setSelectionIndexPath:indexPath];
	}
}

- (IBAction) refresh:(id) sender
{
	NSDictionary * selection = [[treeController selectedObjects] lastObject];
	
	Device * device = [selection valueForKey:DEVICE];
	
	if ([device isKindOfClass:[Device class]])
		[device fetchStatus];
}	

- (IBAction) refreshInfo:(id) sender
{
	NSDictionary * selection = [[treeController selectedObjects] lastObject];
	
	Device * device = [selection valueForKey:DEVICE];
	
	if ([device isKindOfClass:[Device class]])
		[device fetchInfo];
}	

- (IBAction) setComputerLocation:(id) sender
{
	PreferencesManager * pm = [PreferencesManager sharedInstance];
	
	[pm preferencesWindow:sender];
	[pm selectTabNamed:@"Site"];
}

- (void) requestSnapshot:(NSNotification *) theNote
{
	NSMutableArray * selectedSnapshots = [NSMutableArray array];

	NSDictionary * selection = [[treeController selectedObjects] lastObject];

	if ([selection valueForKey:TRIGGER])
	{
		Trigger * trigger = [selection valueForKey:TRIGGER];
	
		NSEnumerator * iter = [[snapshots arrangedObjects] objectEnumerator];
		Snapshot * snapshot = nil;
		while (snapshot = [iter nextObject])
		{
			if ([[snapshot identifier] isEqual:[trigger valueForKey:@"snapshot"]])
				[selectedSnapshots addObject:snapshot];
		}
		
		[snapshots setSelectedObjects:selectedSnapshots];
	}

	[NSApp beginSheet:snapshotsPanel modalForWindow:addTriggerPanel modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

- (void) requestScript:(NSNotification *) theNote
{
	NSDictionary * selection = [[treeController selectedObjects] lastObject];
	
	if ([selection valueForKey:TRIGGER])
	{
		Trigger * trigger = [selection valueForKey:TRIGGER];
		
		FSRef foundRef;
		FSFindFolder (kUserDomain, kDesktopFolderType, kCreateFolder, &foundRef);
		
		unsigned char path[1024];
		FSRefMakePath (&foundRef, path, sizeof(path));

		NSString * directory = [NSString stringWithUTF8String:(char *) path];
		NSString * file = nil;
	
		if ([trigger valueForKey:@"script"])
		{
			NSString * fullPath = [trigger valueForKey:@"script"];
		
			directory = [fullPath stringByDeletingLastPathComponent];
			file = [fullPath lastPathComponent];
		}
	
		NSOpenPanel * panel = [NSOpenPanel openPanel];
		
		[panel setAllowsMultipleSelection:NO];
		[panel setAllowsOtherFileTypes:NO];
		[panel setCanChooseDirectories:NO];
		[panel setCanChooseFiles:YES];
		
		[panel beginSheetForDirectory:directory file:file types:[NSArray arrayWithObject:@"scpt"] 
					   modalForWindow:addTriggerPanel modalDelegate:self 
					   didEndSelector:@selector(scriptPanelDidEnd:returnCode:contextInfo:) 
						  contextInfo:NULL];
	}
}

- (void) scriptPanelDidEnd:(NSOpenPanel *) panel returnCode:(int) returnCode contextInfo:(void  *) contextInfo
{
	if (returnCode == NSCancelButton)
		return;

	NSDictionary * selection = [[treeController selectedObjects] lastObject];
	
	if ([selection valueForKey:TRIGGER])
	{
		Trigger * trigger = [selection valueForKey:TRIGGER];

		[trigger setValue:[[panel filenames] lastObject] forKey:@"script"];
	}
}

- (IBAction) revealTriggerAction:(id) sender
{
	NSDictionary * selection = [[treeController selectedObjects] lastObject];
	
	if ([selection valueForKey:TRIGGER])
	{
		Trigger * trigger = [selection valueForKey:TRIGGER];
		
		if ([[trigger action] isEqual:@"Snapshot"])
		{
			[self dismissTriggerEditor:sender];
			
			NSEnumerator * iter = [[snapshots arrangedObjects] objectEnumerator];
			Snapshot * snapshot = nil;
			while (snapshot = [iter nextObject])
			{
				if ([[snapshot identifier] isEqual:[trigger valueForKey:@"snapshot"]])
				{
					NSIndexPath * indexPath = nil;
					
					if (indexPath == nil)
						indexPath = [self indexPathForObject:snapshot tree:[treeController content]];
					
					[treeController setSelectionIndexPath:indexPath];
				}
			}
		}
		else if ([[trigger action] isEqual:@"Script"])
			[[NSWorkspace sharedWorkspace] selectFile:[trigger valueForKey:@"script"] inFileViewerRootedAtPath:nil];
	}
}

- (NSIndexPath *) selectionIndexPath
{
	return [treeController selectionIndexPath];
}

- (void) setSelectionPath:(NSIndexPath *) indexPath
{
	[treeController setSelectionIndexPath:indexPath];
}

- (NSSize) mapSize
{
	return [mapView frame].size;
}

- (IBAction) toggleCameraPanel:(id) sender
{
	if ([cameraPanel isVisible])
		[cameraPanel orderOut:sender];
	else
		[cameraPanel makeKeyAndOrderFront:sender];
}

@end
