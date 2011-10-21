//
//  ASX10Address.h
//  Shion Framework
//
//  Created by Chris Karr on 12/12/08.
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
#import "ASAddress.h"

#define X10_ALL_LIGHTS_OFF @"X10: All Lights Off"
#define X10_STATUS_OFF @"X10: Status Off"
#define X10_ON @"X10: On"
#define X10_PRESET_DIM @"X10: Preset Dim"
#define X10_ALL_LIGHTS_ON @"X10: All Lights On"
#define X10_HAIL_ACK @"X10: Hail Acknowledgement"
#define X10_BRIGHT @"X10: Bright"
#define X10_STATUS_ON @"X10: Status On"
#define X10_EXTENDED_CODE @"X10: Extended Code"
#define X10_STATUS_REQUEST @"X10: Status Request"
#define X10_OFF @"X10: Off"
#define X10_ALL_OFF @"X10: All Off"
#define X10_HAIL_REQUEST @"X10: Hail Request"
#define X10_DIM @"X10: Dim"
#define X10_EXTENDED_ANALOG @"X10: Extended Analog"

#define X10_STATUS_ON_CODE 0x0d
#define X10_STATUS_OFF_CODE 0x0e

@interface ASX10Address : ASAddress 
{
	NSString * xTenAddress;
}

- (void) setAddress:(NSString *) address;

- (unsigned char) getAddressByte;

+ (NSString *) stringForAddress:(unsigned char) byte;
+ (NSString *) stringForCommand:(unsigned char) byte;

@end
