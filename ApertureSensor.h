//
//  ApertureSensor.h
//  Shion
//
//  Created by Chris Karr on 4/6/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Sensor.h"

#define APERTURE_SENSOR @"Aperture Sensor"

@interface ApertureSensor : Sensor 
{

}

- (BOOL) open;

@end
