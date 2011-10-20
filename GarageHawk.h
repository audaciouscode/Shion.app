//
//  GarageHawk.h
//  Shion
//
//  Created by Chris Karr on 10/8/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Device.h"

#define GARAGE_HAWK @"GarageHawk"


@interface GarageHawk : Device 
{

}

- (void) close;

- (BOOL) isClosed;

@end
