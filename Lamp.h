//
//  Lamp.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Appliance.h"

#define LAMP @"Lamp"

@interface Lamp : Appliance
{

}

- (void) setLevel:(NSNumber *) level;
- (void) dim:(id) sender;
- (void) brighten:(id) sender;

@end
