//
//  ASSprinklerSetConfigurationCommand.h
//  Shion Framework
//
//  Created by Chris Karr on 2/5/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASCommand.h"

@interface ASSprinklerSetConfigurationCommand : ASCommand 
{
	BOOL _enabled;
}

- (void) setEnabled:(BOOL) enable;
- (BOOL) enabled;

@end
