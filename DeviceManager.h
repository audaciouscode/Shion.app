//
//  DeviceManager.h
//  Shion
//
//  Created by Chris Karr on 12/21/08.
//  Copyright 2008 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Device.h"

@interface DeviceManager : NSObject 
{
	NSMutableArray * devices;
	
	NSTimer * refreshTimer;
	
	unsigned int currentStatusDevice;
}

+ (DeviceManager *) sharedInstance;

- (NSArray *) devices;

- (Device *) createDevice:(NSString *) type platform:(NSString *) platform;

- (void) saveDevices;
- (void) removeDevice:(Device *) device;

- (IBAction) refreshDevices:(id) sender;

- (void) sendCommand:(NSDictionary *) command;

- (Device *) deviceWithIdentifier:(NSString *) identifier;

@end
