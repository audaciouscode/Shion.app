//
//  TriggerManager.h
//  Shion
//
//  Created by Chris Karr on 5/12/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Trigger.h"
#import "MobileClient.h"

#define DATE_TRIGGER @"Date & Time"
#define SOLAR_TRIGGER @"Sunrise & Sunset"
#define X10_TRIGGER @"X10 Command"
#define MOTION_TRIGGER @"Motion Sensor"
#define APERTURE_TRIGGER @"Aperture Sensor"
#define PHONE_TRIGGER @"Telephone & Modem"
#define TEMPERATURE_TRIGGER @"Temperature"
#define LOCATION_TRIGGER @"Mobile Device Location"

@interface TriggerManager : NSObject 
{
	NSMutableArray * triggers;
	NSMutableDictionary * state;
	
	NSTimer * heartbeat;
}

+ (TriggerManager *) sharedInstance;

- (void) removeTrigger:(Trigger *) trigger;
- (Trigger *) createTrigger:(NSString *) triggerType;

- (NSArray *) triggers;
- (void) saveTriggers;

- (Trigger *) triggerWithIdentifier:(NSString *) identifier;
- (void) distanceTest:(MobileClient *) mobileDevice;

- (void) deviceUpdate:(NSNotification *) theNote;

@end
