//
//  MobileClient.h
//  Shion
//
//  Created by Chris Karr on 8/16/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Device.h"

#define MOBILE_DEVICE @"Mobile Device"

@interface MobileClient : Device 
{
	NSTimer * statusTimer;
	NSDate * lastStatus;
	NSDate * connectedDate;
	
	NSDate * lastFetch;
}

+ (MobileClient *) mobileClient;

- (void) setLatitude:(NSNumber *) latitude longitude:(NSNumber *) longitude;
- (void) setStatus:(NSString *) status;
- (void) setLastCaller:(NSString *) lastCaller;
- (void) setLocationError:(NSString *) error;

- (void) beacon;

@end
