//
//  ASThermostatDevice.m
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

#import "ASThermostatDevice.h"
#import "ASDeviceController.h"

@implementation ASThermostatDevice

- (ASThermostatDevice *) init
{
	if (self = [super init])
	{
		_temperature = nil;
		_mode = 0xff;
		_heatPoint = nil;
		_coolPoint = nil;
		propertyQueue = [[NSMutableArray alloc] init];
		resetProperty = nil;
	}
	
	return self;
}

- (void) reset:(NSTimer *) theTimer
{
	[propertyQueue removeAllObjects];
	[resetProperty invalidate];
	resetProperty = nil;
}

- (void) addPropertyToQueue:(NSString *) property
{
	[propertyQueue addObject:property];
	
	if (resetProperty != nil)
	{
		[resetProperty invalidate];
		resetProperty = nil;
	}
	
	resetProperty = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(reset:) userInfo:nil repeats:NO];
}

- (NSString *) popPropertyFromQueue
{
	NSString * property = nil;
	
	if ([propertyQueue count] > 0)
	{
		property = [propertyQueue objectAtIndex:0];
		
		[propertyQueue removeObjectAtIndex:0];
	}
	
	return property;
}


- (void) dealloc
{
	if (_temperature != nil)
		[_temperature  release];

	if (_heatPoint != nil)
		[_heatPoint  release];

	if (_coolPoint != nil)
		[_coolPoint  release];

	[propertyQueue release];
	
	[super dealloc];
}

- (void) setTemperature:(NSNumber *) temperature
{
	if (_temperature != nil)
		[_temperature  release];
	
	_temperature = [temperature retain];
}

- (NSNumber *) getTemperature
{
	return _temperature;
}

- (void) setMode:(unsigned char) mode
{
	_mode = mode;
}

- (unsigned char) getMode
{
	return _mode;
}

- (void) setState:(unsigned char) state
{
	_state = state;
}

- (unsigned char) getState
{
	return _state;
}

- (NSNumber *) getHeatPoint
{
	return _heatPoint;
}

- (void) setHeatPoint:(NSNumber *) heatPoint
{
	if (_heatPoint != nil)
		[_heatPoint  release];

	_heatPoint = [heatPoint retain];

	/*	NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[[self getAddress] description] forKey:DEVICE_ADDRESS];
		[userInfo setObject:[self getHeatPoint] forKey:THERMOSTAT_HEAT_POINT];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
	 */
}

- (NSNumber *) getCoolPoint
{
	return _coolPoint;
}

- (void) setCoolPoint:(NSNumber *) coolPoint
{
	if (_coolPoint != nil)
		[_coolPoint  release];
	
	_coolPoint = [coolPoint retain];

	/* if (![_coolPoint isEqual:coolPoint])
	{
		_coolPoint = coolPoint;

		NSMutableDictionary * userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[[self getAddress] description] forKey:DEVICE_ADDRESS];
		[userInfo setObject:[self getCoolPoint] forKey:THERMOSTAT_COOL_POINT];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DEVICE_UPDATE_NOTIFICATION object:nil userInfo:userInfo];
	} */
}

- (void) resetInformation
{
	[self setTemperature:nil];
	[self setHeatPoint:nil];
	[self setCoolPoint:nil];
	
	[self setMode:0xff];
	[self setState:0xff];
}

- (NSString *) productCode
{
	return @"05FF";
}


@end
