//
//  SetThermostatHeatPointCommand.h
//  Shion
//
//  Created by Chris Karr on 8/15/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DeviceCommand.h"

@interface SetThermostatHeatPointCommand : DeviceCommand 
{
	int heat;
}

- (void) setHeat:(int) heatPoint;

@end
