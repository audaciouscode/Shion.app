//
//  ASSprinklerOnCommand.h
//  Shion Framework
//
//  Created by Chris Karr on 11/23/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ASCommand.h"

@interface ASSprinklerOnCommand : ASCommand
{
	NSNumber * unit;
}

- (void) setUnit:(NSNumber *) sprinklerUnit;
- (NSNumber *) unit;

@end
