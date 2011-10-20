//
//  SetThermostatModeCommand.h
//  Shion
//
//  Created by Chris Karr on 8/15/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DeviceCommand.h"

@interface SetThermostatModeCommand : DeviceCommand 
{
	NSString * mode;
}

-(void) setMode:(NSString *) newMode;

@end
