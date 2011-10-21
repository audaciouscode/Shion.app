//
//  ASPowerLinc1132Controller.h
//  Shion Framework
//
//  Created by Chris Karr on 4/2/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/IOCFPlugIn.h>

#import "ASX10Controller.h"

#define COMMAND_BYTES @"Command Bytes"

@interface ASPowerLinc1132Controller : ASX10Controller 
{
	IOHIDDeviceInterface122** controllerHID;
	
	NSMutableData * pending;
	
	BOOL ready;
	
	ASCommand * currentCommand;
	
	NSTimer * wakeup;
	NSDate * lastUpdate;
}

+ (ASPowerLinc1132Controller *) findController;
- (ASPowerLinc1132Controller *) initWithHID:(IOHIDDeviceInterface122**) hid;

- (void) transmitBytes;

// Device commands

- (void) resendCommand;

- (void) setReady:(BOOL) isReady;
- (BOOL) isFinished;

@end
