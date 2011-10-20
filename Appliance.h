//
//  Appliance.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Device.h"

#define APPLIANCE @"Appliance"
#define DEVICE_LEVEL @"level"
#define USER_DEVICE_LEVEL @"user_level"

@interface Appliance : Device
{

}

- (void) setActive:(BOOL) active;
- (BOOL) active;

- (NSNumber *) level;

@end
