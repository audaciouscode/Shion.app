//
//  ASDeviceController.h
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

#include <stdarg.h>

#import <Cocoa/Cocoa.h>

#import "ASCommand.h"
#import "ASDevice.h"
#import "ShionLog.h"

#define AS_STATUS 0x01
#define AS_ACTIVATE 0x02
#define AS_DEACTIVATE 0x03
#define AS_INCREASE 0x04
#define AS_DECREASE 0x05
#define AS_SET_LEVEL 0x06

#define AS_GET_HVAC_TEMP 0x06
#define AS_GET_HVAC_MODE 0x07
#define AS_SET_HVAC_MODE 0x08
#define AS_GET_HVAC_STATE 0x09
#define AS_ACTIVATE_HVAC_BROADCAST 0x0a
#define AS_SET_HEAT_POINT 0x0b
#define AS_SET_COOL_POINT 0x0c
#define AS_GET_HEAT_POINT 0x0d
#define AS_GET_COOL_POINT 0x0e

#define AS_GET_RAMP_RATE 0x0f
#define AS_SET_RAMP_RATE 0x10

#define AS_GET_INFO 0x11

#define AS_ACTIVATE_FAN 0x12
#define AS_DEACTIVATE_FAN 0x13

#define AS_CHIME 0x14

#define AS_ALL_UNITS_OFF 0x15
#define AS_ALL_LIGHTS_ON 0x16
#define AS_ALL_LIGHTS_OFF 0x17

#define AS_SPRINKLER_ON 0x18
#define AS_SPRINKLER_OFF 0x19

#define AS_GET_SPRINKLER_VALVE_STATUS 0x1a
#define AS_GET_SPRINKLER_CONFIGURATION 0x1b

#define AS_SET_SPRINKLER_DIAGNOSTICS 0x1c
#define AS_SET_SPRINKLER_PUMP 0x1d
#define AS_SET_SPRINKLER_RAIN 0x1e

#define AS_RESET_POWER_METER 0x1f

#define AS_LOCK 0x20
#define AS_UNLOCK 0x21

#define AS_GARAGE_CLOSE 0x22

#define CONTROLLER_DEVICE @"Controller Device"

#define COMMAND_BYTES @"Command Bytes"

#define X10_ADDRESS @"X10 Address"
#define X10_COMMAND @"X10 Command"
#define X10_COMMAND_NOTIFICATION @"X10 Command Notification"

#define HARDWARE_ERROR @"Hardware Error"
#define HARDWARE_ERROR_MSG @"Hardware Error Message"

@interface ASDeviceController : NSObject 
{
	NSMutableArray * devices;
	NSMutableArray * commandQueue;
	
	NSString * name;
	NSString * type;
	ASAddress * address;
}

+ (ASDeviceController *) controllerForDevice:(ASDevice *) device skip:(NSArray *) skip;
+ (ASDeviceController *) controllerForDevice:(ASDevice *) device;
+ (NSArray *) findControllers;

- (NSArray *) devices;
- (void) refresh;
- (void) queueCommand: (ASCommand *) command;
- (BOOL) acceptsCommand: (ASCommand *) command;

// - (void) executeNextCommand;

- (NSArray *) queuedCommands;

- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind;
- (ASCommand *) commandForDevice: (ASDevice *)device kind:(unsigned int) commandKind value:(NSObject *) value;

- (NSString *) getName;
- (void) setName:(NSString *) new_name;

- (NSString *) getType;
- (void) setType:(NSString *) new_type;

- (ASAddress *) getAddress;
- (void) setAddress:(NSString *) new_address;

- (NSString *) stringForData:(NSData *) data;
- (void) close;

- (void) resetController;

- (void) closeController;

@end
