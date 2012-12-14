//
//  ASSprinklerDevice.h
//  Shion Framework
//
//  Created by Chris Karr on 11/23/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASDevice.h"

#define SPRINKLER_DIAGNOSTICS @"Sprinkler: In Diagnostic Mode"
#define SPRINKLER_RAINING @"Sprinkler: Rain Detected"
#define SPRINKLER_VALVES_DISABLED @"Sprinkler: Valves Disabled"
#define SPRINKLER_RAIN_ENABLED @"Sprinkler: Rain Sensor Enabled"
#define SPRINKLER_METER_BROADCAST @"Sprinkler: Broadcast Meter Changes"
#define SPRINKLER_VALVES_BROADCAST @"Sprinkler: Broadcast Valve Changes"
#define SPRINKLER_PUMP_ENABLED @"Sprinkler: Pump Enabled"

@interface ASSprinklerDevice : ASDevice 
{

}

@end
