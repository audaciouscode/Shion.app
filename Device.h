//
//  Device.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ASDevice.h"

#import "ASMutableDictionary.h"

#define PLATFORM_X10 @"X10"
#define PLATFORM_INSTEON @"Insteon"

#define IDENTIFIER @"identifier"
#define PLATFORM @"platform"
#define NAME @"name"
#define LOCATION @"location"
#define ADDRESS @"address"
#define MODEL @"model"
#define VERSION @"version"
#define DESCRIPTION @"description"
#define TYPE @"type"
#define FRAMEWORK_DEVICE @"framework_device"
#define LAST_UPDATE @"last_update"

#define LAST_CHECK @"last_check"
#define LAST_RESPONSE @"last_response"

@interface Device : ASMutableDictionary
{

}

+ (Device *) deviceFromData:(NSData *) data;

+ (Device *) deviceForType:(NSString *) type platform:(NSString *) platform;

- (NSDictionary *) snapshotValues;

- (NSString *) identifier;

- (NSString *) address;
- (void) setAddress:(NSString *) address;

- (NSArray *) events;
- (void) addEvent:(NSManagedObject *) event;

- (NSString *) platform;
- (void) setPlatform:(NSString *) platform;

- (NSString *) name;
- (void) setName:(NSString *) name;

- (NSString *) type;

- (NSString *) location;
- (void) setLocation:(NSString *) location;

- (NSString *) model;
- (void) setModel:(NSString *) model;

- (NSString *) version;
- (void) setVersion:(NSString *) version;

- (NSString *) description;
- (void) setDescription:(NSString *) description;

- (NSString *) platform;

- (BOOL) checksStatus;
- (void) setChecksStatus:(BOOL) checkStatus;

- (void) arm;
- (void) disarm;
- (BOOL) armed;

- (ASDevice *) device;
- (void) setDevice:(ASDevice *) device;

- (NSData *) data;

- (void) fetchStatus;
- (void) fetchInfo;
- (void) recordResponse;
- (BOOL) responsive;

- (Device *) canonicalDevice;

- (NSString *) snapshotDescription:(NSDictionary *) snapValues;

- (NSString *) state;

@end
