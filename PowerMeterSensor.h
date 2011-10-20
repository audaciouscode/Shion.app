//
//  PowerMeterSensor.h
//  Shion
//
//  Created by Chris Karr on 7/4/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Device.h"

#define POWER_METER_SENSOR @"Power Meter Sensor"
#define POWER_LEVEL @"level"
#define POWER_TOTAL @"total"

#define CURRENT_POWER @"current_power"
#define ACCUMULATED_POWER @"accumulated_power"

@interface PowerMeterSensor : Device
{
	
}

- (NSNumber *) level;

- (void) setCurrentPower:(NSNumber *) power;
- (void) setTotalPower:(NSNumber *) power;

- (BOOL) canReset;

@end
