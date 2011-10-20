//
//  Thermostat.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Device.h"

#define THERMOSTAT @"Thermostat"

@interface Thermostat : Device
{

}

- (NSString *) mode;
- (void) setMode:(NSString *) mode;

- (NSNumber *) temperature;
- (void) setTemperature:(NSNumber *) temperature;

- (NSNumber *) heatPoint;
- (void) setHeatPoint:(NSNumber *) heatPoint;

- (NSNumber *) coolPoint;
- (void) setCoolPoint:(NSNumber *) coolPoint;

- (BOOL) fanActive;
- (void) setFanState:(BOOL) state;

- (void) setRunning:(BOOL) running;
- (BOOL) isRunning;

@end
