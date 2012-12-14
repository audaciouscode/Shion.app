//
//  ToggleDevice.m
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

#import "ASToggleDevice.h"
#import "ASDeviceController.h"

#define IS_ACTIVE @"Is Active?"
#define RAMP_RATE @"Ramp Rate"

@implementation ASToggleDevice

- (BOOL) isActive
{
	NSNumber * active = [properties valueForKey:IS_ACTIVE];
	
	if (active == nil)
		return NO;
	
	return [active boolValue];
}

- (void) setActive:(BOOL) active
{
	[properties setValue:[NSNumber numberWithBool:active] forKey:IS_ACTIVE];
}

- (unsigned char) rampRate
{
	NSNumber * rate = [self valueForKey:RAMP_RATE];
	
	if (rate != nil)
		return [rate unsignedCharValue];
	
	return 0xFF;
}

- (void) setRampRate:(unsigned char) rate
{
	if (rate > 0x1F)
		[self removeValueForKey:RAMP_RATE];
	else
		[self setValue:[NSNumber numberWithUnsignedChar:rate] forKey:RAMP_RATE];
}

- (NSString *) productCode
{
	return @"02FF";
}


@end
