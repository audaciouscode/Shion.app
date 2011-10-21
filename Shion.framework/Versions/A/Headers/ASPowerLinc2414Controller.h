//
//  ASPowerLincUSBController.h
//  Shion Framework
//
//  Created by Chris Karr on 12/9/08.
//  Copyright 2008 Audacious Software. 
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#import <Cocoa/Cocoa.h>
#import "ASPowerLincController.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDLib.h>
#include <IOKit/IOCFPlugIn.h>

#define COMMAND_BYTES @"Command Bytes"

@interface ASPowerLinc2414Controller : ASPowerLincController 
{
	IOHIDDeviceInterface122** controllerHID;

	NSMutableData * pending;

	BOOL ready;
	
	ASCommand * currentCommand;
	
	NSTimer * wakeup;
	NSDate * lastUpdate;
}

+ (ASPowerLinc2414Controller *) findController;
- (ASPowerLinc2414Controller *) initWithHID:(IOHIDDeviceInterface122**) hid;

- (void) transmitBytes;

// Device commands

- (void) resendCommand;
- (void) processUploadMessage:(NSData *) message high:(unsigned char) high low:(unsigned char) low;
- (void) processEvent:(unsigned char) event;
- (void) processGetVersion:(NSData *) message;

- (void) setReady:(BOOL) isReady;
- (BOOL) isFinished;

- (void) sendNativeCommand:(unsigned int) commandKind;
- (void) updated;

@end
