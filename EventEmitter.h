//
//  EventEmitter.h
//  Shion
//
//  Created by Chris Karr on 1/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

#define EVENT_KIND @"kind"
#define EVENT_VALUE @"value"
#define EVENT_EMITTED @"Event Emitted"

#define TIME_EVENT @"Time Event"
#define HARDWARE_EVENT @"Hardware Error"
#define SOLAR_EVENT @"Solar Event"
#define X10_EVENT @"X10 Event"
#define SHION_LAUNCH_EVENT @"Shion Launch"
#define TEMPERATURE_EVENT @"Temperature Change"

#define SUNRISE_DIFF @"Sunrise Diff"
#define SUNSET_DIFF @"Sunset Diff"

@interface EventEmitter : NSObject 
{
	NSTimer * heartbeat;
	
	NSTimer * sunTimer;
	MachineLocation * location;
	
	IBOutlet NSWindow * shionWindow;
	IBOutlet NSArrayController * devices;
}

- (void) emitEvent:(NSString *) kind value:(id) value;

@end
