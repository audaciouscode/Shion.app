//
//  House.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Device.h"

#define HOUSE @"House"

@interface House : Device
{

}

- (NSArray *) devices;

- (void) deactivateLights;
- (void) activateLights;
- (void) deactivateAll;

@end
