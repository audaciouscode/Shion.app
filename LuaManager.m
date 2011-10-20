//
//  LuaManager.m
//  Shion
//
//  Created by Chris Karr on 4/19/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "LuaManager.h"

#import <LuaCore/LuaCore.h>

#import "XMPPManager.h"
#import "ConsoleManager.h"

#import "DeviceManager.h"
#import "Device.h"
#import "SnapshotManager.h"
#import "Snapshot.h"
#import "TriggerManager.h"
#import "Trigger.h"

#import "Appliance.h"
#import "Lamp.h"
#import "Chime.h"
#import "Thermostat.h"
#import "House.h"
#import "MobileClient.h"
#import "Camera.h"

#import <LuaCore/lua.h>

@implementation LuaManager

static LuaManager * sharedInstance = nil;

+ (LuaManager *) sharedInstance
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

- (id) init
{
	if (self = [super init])
	{
		windowController = [[NSWindowController alloc] initWithWindowNibName:@"LuaWindow" owner:self];
	}
	
	return self;
}

- (NSDictionary *) runScript:(NSString *) script
{
	NSMutableDictionary * resultDict = [NSMutableDictionary dictionary];

	LCLua * lua = [LCLua readyLua];

	[lua pushGlobalObject:self withName:@"shion"];

	[lua runBuffer:script];

	const char * luaString = lua_tostring([lua state], -1);
	
	if (luaString != NULL)
		[resultDict setValue:[NSString stringWithCString:luaString encoding:NSUTF8StringEncoding] forKey:@"result"];

	return resultDict;
}

- (IBAction) luaWindow:(id) sender
{
	[NSApp activateIgnoringOtherApps:YES];
	
	[windowController showWindow:sender];
	
	[window center];
	
	[window makeKeyAndOrderFront:sender];
}

- (IBAction) runSource:(id) sender
{
	NSString * sourceText = [source string];
	
	NSDictionary * resultDict = [self runScript:sourceText];
	
	[results setString:[resultDict description]];
}

- (Device *) deviceForIdentifier:(NSString *) identifier
{
	Device * finalDevice = nil;
	
	NSEnumerator * iter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * device = nil;
	while (device = [iter nextObject])
	{
		if (finalDevice == nil &&[[device identifier] isEqual:identifier])
			finalDevice = device;
	}
	
	return finalDevice;
}	

- (Snapshot *) snapshotForIdentifier:(NSString *) identifier
{
	Snapshot * finalSnapshot = nil;
	
	NSEnumerator * iter = [[[SnapshotManager sharedInstance] snapshots] objectEnumerator];
	Snapshot * snapshot = nil;
	while (snapshot = [iter nextObject])
	{
		if (finalSnapshot == nil && [[snapshot identifier] isEqual:identifier])
			finalSnapshot = snapshot;
	}
	
	return finalSnapshot;
}	

- (Trigger *) triggerForIdentifier:(NSString *) identifier
{
	Trigger * finalTrigger = nil;
	
	NSEnumerator * iter = [[[TriggerManager sharedInstance] triggers] objectEnumerator];
	Trigger * trigger = nil;
	while (trigger = [iter nextObject])
	{
		if (finalTrigger == nil && [[trigger identifier] isEqual:identifier])
			finalTrigger = trigger;
	}
	
	return finalTrigger;
}	

- (NSString *) deviceWithName:(NSString *) name
{
	NSString * deviceId = nil;
	
	NSEnumerator * iter = [[[DeviceManager sharedInstance] devices] objectEnumerator];
	Device * device = nil;
	while (device = [iter nextObject])
	{
		if (deviceId == nil && [[device name] isEqual:name])
			deviceId = [device identifier];
	}
	
	return deviceId;
}

- (NSString *) typeOfDevice:(NSString *) device
{
	return [[self deviceForIdentifier:device] identifier];
}

- (BOOL) activateDevice:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Appliance class]])
	{
		Appliance * a = (Appliance *) d;
		
		[a setActive:YES];
		
		return YES;
	}

	return NO;
}

- (BOOL) deactivateDevice:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Appliance class]])
	{
		Appliance * a = (Appliance *) d;
		
		[a setActive:NO];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) setLevel:(NSNumber *) level forDevice:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Lamp class]])
	{
		Lamp * l = (Lamp *) d;

		level = [NSNumber numberWithUnsignedInt:(255 * [level floatValue])];
		
		[l setLevel:level];
		
		return YES;
	}
	
	return NO;
}

- (NSNumber *) levelOfDevice:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Appliance class]])
	{
		Appliance * a = (Appliance *) d;
		
		NSNumber * level = [a level];
		
		return [NSNumber numberWithFloat:([level floatValue] / 255)];
	}
	
	return [NSNumber numberWithInt:-1];
}

- (BOOL) dimDevice:(NSString *) device
{
	// TODO
	
	return NO;
}

- (BOOL) brightenDevice:(NSString *) device
{
	// TODO
	
	return NO;
}

- (BOOL) ringDevice:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Chime class]])
	{
		Chime * c = (Chime *) d;
		
		[c chime];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) updateLatitude:(NSNumber *) lat longitude:(NSNumber *) lon forDevice:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[MobileClient class]])
	{
		MobileClient * m = (MobileClient *) d;
		
		[m setLatitude:lat longitude:lon];
		[m setLocationError:nil];
		
		[[TriggerManager sharedInstance] distanceTest:m];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) updateLocationError:(NSString *) errorString forDevice:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[MobileClient class]])
	{
		MobileClient * m = (MobileClient *) d;
			
		[m setLatitude:nil longitude:nil];
		[m setLocationError:errorString];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) updateMobileDevice:(NSString *) device name:(NSString *) name address:(NSString *) address platform:(NSString *) platform model:(NSString *) model version:(NSString *) version
{
	Device * d = [self deviceForIdentifier:device];
	
	if (d == nil)
	{
		d = [[DeviceManager sharedInstance] createDevice:@"Mobile Device" platform:platform];
		
		[d setValue:device forKey:IDENTIFIER];
	}

	if ([d isKindOfClass:[MobileClient class]])
	{
		[d setName:name];
		[d setAddress:address];
		[d setPlatform:platform];
		[d setModel:model];
		[d setVersion:version];

		[[ConsoleManager sharedInstance] reloadDevices];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) updateMobileDevice:(NSString *) device caller:(NSString *) caller
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[MobileClient class]])
	{
		MobileClient * m = (MobileClient *) d;
		
		[m setLastCaller:caller];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) updateMobileDevice:(NSString *) device status:(NSString *) status
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[MobileClient class]])
	{
		MobileClient * m = (MobileClient *) d;
		
		[m setStatus:status];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) allLightsOnForDevice:(NSString *) device
{
	// TODO
	
	return NO;
}

- (BOOL) allLightsOffForDevice:(NSString *) device
{
	// TODO
	
	return NO;
}

- (BOOL) allUnitsOffForDevice:(NSString *) device
{
	// TODO
	
	return NO;
}

- (BOOL) sendEnvironmentToJid:(NSString *) jid
{
	return [[XMPPManager sharedInstance] sendEnvironmentToJid:jid];
}
	
- (BOOL) sendEventsForDevice:(NSString *) device toJid:(NSString *) jid
{
	return [[XMPPManager sharedInstance] sendEventsForDevice:device toJid:jid];
}

- (BOOL) sendEventsForDevice:(NSString *) device toJid:(NSString *) jid forDateString:(NSString *) dateString
{
	return [[XMPPManager sharedInstance] sendEventsForDevice:device toJid:jid forDateString:dateString];
}

- (BOOL) setMode:(NSString *) mode forThermostat:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Thermostat class]])
	{
		Thermostat * t = (Thermostat *) d;
		
		[t setMode:mode];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) setHeatPoint:(NSNumber *) point forThermostat:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Thermostat class]])
	{
		Thermostat * t = (Thermostat *) d;
		
		[t setHeatPoint:point];
		
		return YES;
	}

	return NO;
}

-(BOOL) setCoolPoint:(NSNumber *) point forThermostat:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Thermostat class]])
	{
		Thermostat * t = (Thermostat *) d;
		
		[t setCoolPoint:point];

		return YES;
	}

	return NO;
}

- (BOOL) activateFanForThermostat:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Thermostat class]])
	{
		Thermostat * t = (Thermostat *) d;
		
		[t setFanState:YES];
		
		return YES;
	}

	return NO;
}

- (BOOL) deactivateFanForThermostat:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[Thermostat class]])
	{
		Thermostat * t = (Thermostat *) d;
		
		[t setFanState:NO];

		return YES;
	}

	return NO;
}

- (BOOL) activateSnapshot:(NSString *) snapshot
{
	Snapshot * s = [self snapshotForIdentifier:snapshot];
	
	if (s != nil)
	{
		[s execute];
	
		return YES;
	}
	
	return NO;
}

- (BOOL) allOffForHouse:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[House class]])
	{
		House * h = (House *) d;
		
		[h deactivateAll];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) lightsOffForHouse:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[House class]])
	{
		House * h = (House *) d;
		
		[h deactivateLights];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) lightsOnForHouse:(NSString *) device
{
	Device * d = [self deviceForIdentifier:device];
	
	if ([d isKindOfClass:[House class]])
	{
		House * h = (House *) d;
		
		[h activateLights];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) fireTrigger:(NSString *) trigger
{
	Trigger * t = [self triggerForIdentifier:trigger];
	
	if (t != nil)
	{
		[t fire];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) fetchPhotoListForCamera:(NSString *) cameraId
{
	Device * device = [[DeviceManager sharedInstance] deviceWithIdentifier:cameraId];
	
	if (device != nil && [device isKindOfClass:[Camera class]])
	{
		Camera * camera = (Camera *) device;
		
		NSArray * photos = [camera photoList];
		
		[[XMPPManager sharedInstance] transmitPhotoList:photos forCamera:camera];
	}
	
	return NO;
}

- (BOOL) fetchPhoto:(NSString *) photoId forCamera:(NSString *) cameraId
{
	Device * device = [[DeviceManager sharedInstance] deviceWithIdentifier:cameraId];
	
	if (device != nil && [device isKindOfClass:[Camera class]])
	{
		Camera * camera = (Camera *) device;

		NSDictionary * photoDict = [camera photoForId:photoId];
		
		if (photoDict != nil)
			[[XMPPManager sharedInstance] transmitPhoto:photoDict forCamera:camera];
	}
	
	return NO;
}

- (BOOL) fetchPhoto:(NSString *) photoId forCamera:(NSString *) cameraId width:(double) width height:(double) height
{
	Device * device = [[DeviceManager sharedInstance] deviceWithIdentifier:cameraId];
	
	if (device != nil && [device isKindOfClass:[Camera class]])
	{
		Camera * camera = (Camera *) device;
		
		NSDictionary * photoDict = [camera photoForId:photoId];
		
		NSData * data = [photoDict valueForKey:@"data"];
		
		NSImage * image = [[NSImage alloc] initWithData:data];
		
		if ([image isValid])
		{
			[image setScalesWhenResized:YES];
			
			double ratio = width / [image size].width;
			double heightRatio = height / [image size].height;
		
			if (heightRatio > ratio)
				ratio = heightRatio;
		
			NSSize newSize = NSMakeSize([image size].width * ratio, [image size].height * ratio);
		
			NSImage * transmissionImage = [[NSImage alloc] initWithSize:newSize];
			[transmissionImage lockFocus];
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
			[image setSize:newSize];
			[image compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
			[transmissionImage unlockFocus];
			
			NSData * imageData = [transmissionImage  TIFFRepresentation];
			NSBitmapImageRep * imageRep = [NSBitmapImageRep imageRepWithData:imageData];
			NSDictionary * imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.6] forKey:NSImageCompressionFactor];
			NSData * newData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
		
			NSMutableDictionary * newDict = [NSMutableDictionary dictionaryWithDictionary:photoDict];
			[newDict setValue:newData forKey:@"data"];
		
			if (photoDict != nil)
				[[XMPPManager sharedInstance] transmitPhoto:newDict forCamera:camera];
		
			[transmissionImage release];
		}

		[image release];
	}
	
	return NO;
}

- (BOOL) captureImageWithCamera:(NSString *) cameraId
{
	Device * device = [[DeviceManager sharedInstance] deviceWithIdentifier:cameraId];
	
	if (device != nil && [device isKindOfClass:[Camera class]])
	{
		Camera * camera = (Camera *) device;
		
		[camera setValue:@"" forKey:@"take_picture"];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) beaconMobileDevice:(NSString *) cameraId
{
	Device * device = [[DeviceManager sharedInstance] deviceWithIdentifier:cameraId];
	
	if (device != nil && [device isKindOfClass:[MobileClient class]])
	{
		MobileClient * mobileDevice = (MobileClient *) device;
		
		[mobileDevice beacon];
		
		return YES;
	}
	
	return NO;
}

- (BOOL) fetchRecordingsForTivo:(NSString *) tivoId
{
	Device * device = [[DeviceManager sharedInstance] deviceWithIdentifier:tivoId];
	
	if (device != nil && [device isKindOfClass:[Tivo class]])
	{
		Tivo * tivo = (Tivo *) device;

		NSArray * recordings = [tivo recordings];

		[[XMPPManager sharedInstance] transmitRecordings:recordings forTivo:tivo];
	}
	
	return NO;
}


@end
