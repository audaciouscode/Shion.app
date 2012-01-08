//
//  PreferencesManager.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

#import "Controller.h"

#define CONTROLLER_TYPE @"controller_type"
#define CONTROLLER_LOCATION @"controller_location"

#define CONTROLLER_USB @"USB"
#define CONTROLLER_SERIAL @"Serial Port"
#define CONTROLLER_NETWORK @"Network"

#define SERIAL_CONTROLLER_MODEL @"serial_controller_model"
#define SERIAL_CONTROLLER_PORT @"serial_controller_port"

#define NETWORK_CONTROLLER_MODEL @"network_controller_model"
#define NETWORK_CONTROLLER_ADDRESS @"network_controller_address"

#define CONTROLLER_PL2412 @"PowerLinc 2412"
#define CONTROLLER_PL2413 @"PowerLinc 2413"
#define CONTROLLER_PLRFUSB @"INSTEON Portable USB Adapter"
#define CONTROLLER_SL2412 @"SmartLinc 2412N"
#define CONTROLLER_EZSRVE @"SimpleHomeNet EZSrve"
#define CONTROLLER_CM11A @"CM11A (and compatible)"
#define CONTROLLER_CM17A @"CM17A (Firecracker)"

#define MODEM_MODEL @"modem_model"
#define MODEM_PORT @"modem_port"
#define MODEM_LOCATION @"modem_location"

#define MODEM_APPLEUSB @"Apple USB Modem"

#define SITE_ICON @"site_icon"

@interface PreferencesManager : NSObject
{
	SUUpdater * updater;
	IBOutlet NSTextField * addressField;
	NSWindowController * windowController;
	
	IBOutlet NSWindow * window;
	IBOutlet NSTabView * preferenceTabs;
}

+ (PreferencesManager *) sharedInstance;

- (id) valueForKey:(NSString *) key;
- (void) setValue:(id) value forKey:(NSString *) key;

- (IBAction) checkForUpdates:(id) sender;
- (IBAction) serialPortInfo:(id) sender;

- (IBAction) detectOrVerifyNetwork:(id) sender;

- (BOOL) logEvent:(NSString *) eventType;
- (IBAction) revealLogs:(id) sender;

- (IBAction) shionOnlineInfo:(id) sender;

- (IBAction) preferencesWindow:(id) sender;

- (BOOL) confirmQuit;
- (void) setConfirmQuit:(BOOL) confirm;

- (NSDictionary *) controllerDetails;
- (NSDictionary *) phoneDetails;

- (void) showControllerDetails;

- (IBAction) findPositionOnline:(id) sender;

- (BOOL) selectTabNamed:(NSString *) name;

- (IBAction) testNetworkController:(id) sender;

@end
