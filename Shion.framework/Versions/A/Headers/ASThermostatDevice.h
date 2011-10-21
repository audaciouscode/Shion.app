//
//  ASThermostatDevice.h
//  Shion Framework
//
//  Created by Chris Karr on 12/17/08.
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
#import "ASDevice.h"

#define MODE_OFF 0x00
#define MODE_HEAT 0x01
#define MODE_COOL 0x02
#define MODE_AUTO 0x03
#define MODE_FAN 0x04
#define MODE_PROGRAM 0x05
#define MODE_PROGRAM_HEAT 0x06
#define MODE_PROGRAM_COOL 0x07
#define MODE_FAN_OFF 0x08

#define THERMOSTAT_MODE @"Thermostat Mode"
#define THERMOSTAT_TEMPERATURE @"Thermostat Temperature"
#define THERMOSTAT_STATE @"Thermostat State"

#define THERMOSTAT_COOL_POINT @"Thermostat Cool Point"
#define THERMOSTAT_HEAT_POINT @"Thermostat Heat Point"

@interface ASThermostatDevice : ASDevice 
{
	NSNumber * _temperature;
	NSNumber * _heatPoint;
	NSNumber * _coolPoint;
	
	unsigned char _mode;
	unsigned char _state;
	
	NSMutableArray * propertyQueue;
	NSTimer * resetProperty;
}

- (void) resetInformation;

- (void) setTemperature:(NSNumber *) temperature;
- (NSNumber *) getTemperature;

- (void) setMode:(unsigned char) mode;
- (unsigned char) getMode;

- (void) setState:(unsigned char) state;
- (unsigned char) getState;

- (NSNumber *) getHeatPoint;
- (void) setHeatPoint:(NSNumber *) heatPoint;

- (NSNumber *) getCoolPoint;
- (void) setCoolPoint:(NSNumber *) coolPoint;

- (void) addPropertyToQueue:(NSString *) property;
- (NSString *) popPropertyFromQueue;


@end
