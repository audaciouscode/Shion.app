//
//  LuaManager.h
//  Shion
//
//  Created by Chris Karr on 4/19/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LuaManager : NSObject 
{
	IBOutlet NSTextView * source;
	IBOutlet NSTextView * results;
	IBOutlet NSWindow * window;
	
	NSWindowController * windowController;
}

+ (LuaManager *) sharedInstance;
- (NSDictionary *) runScript:(NSString *) script;

- (IBAction) runSource:(id) sender;
- (IBAction) luaWindow:(id) sender;

// Lua methods

- (NSString *) deviceWithName:(NSString *) name;
- (NSString *) typeOfDevice:(NSString *) device;

- (BOOL) activateDevice:(NSString *) device;
- (BOOL) deactivateDevice:(NSString *) device;

- (BOOL) setLevel:(NSNumber *) level forDevice:(NSString *) device;
- (NSNumber *) levelOfDevice:(NSString *) device;

- (BOOL) setLevel:(NSNumber *) level forDevice:(NSString *) device;
- (BOOL) dimDevice:(NSString *) device;
- (BOOL) brightenDevice:(NSString *) device;

- (BOOL) ringDevice:(NSString *) device;

- (BOOL) allLightsOnForDevice:(NSString *) device;
- (BOOL) allLightsOffForDevice:(NSString *) device;
- (BOOL) allUnitsOffForDevice:(NSString *) device;

- (BOOL) setMode:(NSString *) mode forThermostat:(NSString *) device;
- (BOOL) setHeatPoint:(NSNumber *) point forThermostat:(NSString *) device;
- (BOOL) setCoolPoint:(NSNumber *) point forThermostat:(NSString *) device;
- (BOOL) activateFanForThermostat:(NSString *) device;
- (BOOL) deactivateFanForThermostat:(NSString *) device;

- (BOOL) activateSnapshot:(NSString *) snapshot;

- (BOOL) fireTrigger:(NSString *) trigger;

- (BOOL) allOffForHouse:(NSString *) device;
- (BOOL) lightsOffForHouse:(NSString *) device;
- (BOOL) lightsOnForHouse:(NSString *) device;

// Lua XMPP methods

- (BOOL) sendEnvironmentToJid:(NSString *) jid;
- (BOOL) sendEventsForDevice:(NSString *) device toJid:(NSString *) jid;
- (BOOL) sendEventsForDevice:(NSString *) device toJid:(NSString *) jid forDateString:(NSString *) dateString;

- (BOOL) fetchPhotoListForCamera:(NSString *) cameraId;
- (BOOL) fetchPhoto:(NSString *) photoId forCamera:(NSString *) cameraId;
- (BOOL) fetchPhoto:(NSString *) photoId forCamera:(NSString *) cameraId width:(double) width height:(double) height;
- (BOOL) captureImageWithCamera:(NSString *) cameraId;

- (BOOL) beaconMobileDevice:(NSString *) deviceId;

@end
