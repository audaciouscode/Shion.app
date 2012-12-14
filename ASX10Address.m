//
//  ASX10Address.m
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

#import "ASX10Address.h"


@implementation ASX10Address

- (id) getAddress
{
	return xTenAddress;
}

- (void) setAddress:(NSString *) address
{
	if (xTenAddress != nil)
		[xTenAddress release];
	
	xTenAddress = [address retain];
}

- (void) dealloc
{
	if (xTenAddress != nil)
		[xTenAddress release];

	[super dealloc];
}

- (unsigned char) getAddressByte
{
	unsigned char byte = 0x00;
	
	NSString * lowerAddress = [xTenAddress lowercaseString];

	char house = [lowerAddress characterAtIndex:0];

	switch (house)
	{
		case 'a':
			byte = 0x60;
			break;
		case 'b':
			byte = 0xe0;
			break;
		case 'c':
			byte = 0x20;
			break;
		case 'd':
			byte = 0xa0;
			break;
		case 'e':
			byte = 0x10;
			break;
		case 'f':
			byte = 0x90;
			break;
		case 'g':
			byte = 0x50;
			break;
		case 'h':
			byte = 0xd0;
			break;
		case 'i':
			byte = 0x70;
			break;
		case 'j':
			byte = 0xf0;
			break;
		case 'k':
			byte = 0x30;
			break;
		case 'l':
			byte = 0xb0;
			break;
		case 'm':
			byte = 0x00;
			break;
		case 'n':
			byte = 0x80;
			break;
		case 'o':
			byte = 0x40;
			break;
		case 'p':
			byte = 0xc0;
			break;
	}

	if ([lowerAddress length] > 1)
	{
		NSMutableString * unit = [NSMutableString stringWithString:[lowerAddress substringFromIndex:1]];
		
		[unit replaceOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, [unit length])];
		
		if ([unit isEqual:@"1"])
			byte = byte | 0x06;
		else if ([unit isEqual:@"2"])
			byte = byte | 0x0e;
		else if ([unit isEqual:@"3"])
			byte = byte | 0x02;
		else if ([unit isEqual:@"4"])
			byte = byte | 0x0a;
		else if ([unit isEqual:@"5"])
			byte = byte | 0x01;
		else if ([unit isEqual:@"6"])
			byte = byte | 0x09;
		else if ([unit isEqual:@"7"])
			byte = byte | 0x05;
		else if ([unit isEqual:@"8"])
			byte = byte | 0x0d;
		else if ([unit isEqual:@"9"])
			byte = byte | 0x07;
		else if ([unit isEqual:@"10"])
			byte = byte | 0x0f;
		else if ([unit isEqual:@"11"])
			byte = byte | 0x03;
		else if ([unit isEqual:@"12"])
			byte = byte | 0x0b;
		else if ([unit isEqual:@"13"])
			byte = byte | 0x00;
		else if ([unit isEqual:@"14"])
			byte = byte | 0x08;
		else if ([unit isEqual:@"15"])
			byte = byte | 0x04;
		else if ([unit isEqual:@"16"])
			byte = byte | 0x0c;
	}
	
	return byte;
}

+ (NSString *) stringForAddress:(unsigned char) byte
{
	NSMutableString * address = [NSMutableString string];
	
	switch (byte & 0xf0) 
	{
		case 0x60:
			[address appendString:@"A"];
			break;
		case 0xe0:
			[address appendString:@"B"];
			break;
		case 0x20:
			[address appendString:@"C"];
			break;
		case 0xa0:
			[address appendString:@"D"];
			break;
		case 0x10:
			[address appendString:@"E"];
			break;
		case 0x90:
			[address appendString:@"F"];
			break;
		case 0x50:
			[address appendString:@"G"];
			break;
		case 0xd0:
			[address appendString:@"H"];
			break;
		case 0x70:
			[address appendString:@"I"];
			break;
		case 0xf0:
			[address appendString:@"J"];
			break;
		case 0x30:
			[address appendString:@"K"];
			break;
		case 0xb0:
			[address appendString:@"L"];
			break;
		case 0x00:
			[address appendString:@"M"];
			break;
		case 0x80:
			[address appendString:@"N"];
			break;
		case 0x40:
			[address appendString:@"O"];
			break;
		case 0xc0:
			[address appendString:@"P"];
			break;
		default:
			break;
	}

	switch (byte & 0x0f) 
	{
		case 0x06:
			[address appendString:@"1"];
			break;
		case 0x0e:
			[address appendString:@"2"];
			break;
		case 0x02:
			[address appendString:@"3"];
			break;
		case 0x0a:
			[address appendString:@"4"];
			break;
		case 0x01:
			[address appendString:@"5"];
			break;
		case 0x09:
			[address appendString:@"6"];
			break;
		case 0x05:
			[address appendString:@"7"];
			break;
		case 0x0d:
			[address appendString:@"8"];
			break;
		case 0x07:
			[address appendString:@"9"];
			break;
		case 0x0f:
			[address appendString:@"10"];
			break;
		case 0x03:
			[address appendString:@"11"];
			break;
		case 0x0b:
			[address appendString:@"12"];
			break;
		case 0x00:
			[address appendString:@"13"];
			break;
		case 0x08:
			[address appendString:@"14"];
			break;
		case 0x04:
			[address appendString:@"15"];
			break;
		case 0x0c:
			[address appendString:@"16"];
			break;
		default:
			break;
	}
	
	return address;
}

+ (NSString *) stringForCommand:(unsigned char) byte
{
	NSMutableString * command = [NSMutableString string];

	switch (byte & 0xf0) 
	{
		case 0x60:
			[command appendString:@"A"];
			break;
		case 0xe0:
			[command appendString:@"B"];
			break;
		case 0x20:
			[command appendString:@"C"];
			break;
		case 0xa0:
			[command appendString:@"D"];
			break;
		case 0x10:
			[command appendString:@"E"];
			break;
		case 0x90:
			[command appendString:@"F"];
			break;
		case 0x50:
			[command appendString:@"G"];
			break;
		case 0xd0:
			[command appendString:@"H"];
			break;
		case 0x70:
			[command appendString:@"I"];
			break;
		case 0xf0:
			[command appendString:@"J"];
			break;
		case 0x30:
			[command appendString:@"K"];
			break;
		case 0xb0:
			[command appendString:@"L"];
			break;
		case 0x00:
			[command appendString:@"M"];
			break;
		case 0x80:
			[command appendString:@"N"];
			break;
		case 0x40:
			[command appendString:@"O"];
			break;
		case 0xc0:
			[command appendString:@"P"];
			break;
		default:
			break;
	}
	
	[command appendString:@" "];

	switch (byte & 0x0f) 
	{
		case 0x06:
			[command appendString:X10_ALL_LIGHTS_OFF];
			break;
		case 0x0e:
			[command appendString:X10_STATUS_OFF];
			break;
		case 0x02:
			[command appendString:X10_ON];
			break;
		case 0x0a:
			[command appendString:X10_PRESET_DIM];
			break;
		case 0x01:
			[command appendString:X10_ALL_LIGHTS_ON];
			break;
		case 0x09:
			[command appendString:X10_HAIL_ACK];
			break;
		case 0x05:
			[command appendString:X10_BRIGHT];
			break;
		case 0x0d:
			[command appendString:X10_STATUS_ON];
			break;
		case 0x07:
			[command appendString:X10_EXTENDED_CODE];
			break;
		case 0x0f:
			[command appendString:X10_STATUS_REQUEST];
			break;
		case 0x03:
			[command appendString:X10_OFF];
			break;
		case 0x0b:
			[command appendString:X10_PRESET_DIM];
			break;
		case 0x00:
			[command appendString:X10_ALL_OFF];
			break;
		case 0x08:
			[command appendString:X10_HAIL_REQUEST];
			break;
		case 0x04:
			[command appendString:X10_DIM];
			break;
		case 0x0c:
			[command appendString:X10_EXTENDED_ANALOG];
			break;
		default:
			break;
	}
	
	return command;
}


@end
