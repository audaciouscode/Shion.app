//
//  ASSprinklerOnCommand.m
//  Shion Framework
//
//  Created by Chris Karr on 11/23/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "ASSprinklerOnCommand.h"


@implementation ASSprinklerOnCommand

- (void) setUnit:(NSNumber *) sprinklerUnit
{
	if (unit != nil)
		[unit release];
	
	unit = [sprinklerUnit retain];
}

- (NSNumber *) unit
{
	return unit;
}

@end
