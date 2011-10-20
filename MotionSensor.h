//
//  MotionSensor.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Sensor.h"

#define MOTION_SENSOR @"Motion Sensor"

@interface MotionSensor : Sensor
{

}

- (BOOL) detectingMotion;

@end
