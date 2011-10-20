//
//  PowerSensor.h
//  Shion
//
//  Created by Chris Karr on 4/1/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Sensor.h"

#define POWER_SENSOR @"Power Sensor"

@interface PowerSensor : Sensor
{
	
}

- (BOOL) isActive;

@end
