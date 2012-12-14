//
//  ASSprinklerSetConfigurationCommand.m
//  Shion Framework
//
//  Created by Chris Karr on 2/5/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASSprinklerSetConfigurationCommand.h"


@implementation ASSprinklerSetConfigurationCommand

- (void) setEnabled:(BOOL) enable
{
	_enabled = enable;
}

- (BOOL) enabled
{
	return _enabled;
}

@end
