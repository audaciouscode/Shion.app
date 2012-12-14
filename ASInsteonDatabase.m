//
//  ASInsteonDatabase.m
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

#import "ASInsteonDatabase.h"


@implementation ASInsteonDatabase

+ (NSString *) stringForDeviceTypeString:(NSString *) type
{
	NSScanner * hexScanner = [NSScanner scannerWithString:type];
	
	unsigned value = 0;
	
	if ([hexScanner scanHexInt:&value])
	{
		short svalue = (short) value;
		unsigned char * sBytes = (unsigned char *) &svalue;
		
		unsigned char bytes[2];
		bytes[0] = sBytes[1];
		bytes[1] = sBytes[0];
		
		NSData * data = [NSData dataWithBytes:bytes length:2];
		
		return [ASInsteonDatabase stringForDeviceType:data];
	}
	
	return [NSString stringWithFormat:@"Unknown: %@", type];
}

+ (NSString *) stringForDeviceType:(NSData *) type
{
	unsigned char * bytes = (unsigned char *) [type bytes];

	/*	if ([type length] == 2)
	{
	 unsigned char * bytes = (unsigned char *) [type bytes];
		
		if (bytes[0] == 0x03)
		{
			// Network Bridges
			
			if (bytes[1] == 0x01)
				return @"PowerLinc Serial [2414S]";
			else if (bytes[1] == 0x02)
				return @"PowerLinc USB [2414U]";
			else if (bytes[1] = 0x03)
				return @"Icon PowerLinc Serial [2814S]";
			else if (bytes[1] = 0x04)
				return @"Icon PowerLinc USB [2814U]";
			else if (bytes[1] = 0x05)
				return @"Smarthome Power Line Modem Serial [2412S]";
		}
		else if (bytes[0] == 0x01)
		{
			if (bytes[1] == 0x00)
				return @"LampLinc V2 [2456D3]";
			else if (bytes[1] == 0x01)
				return @"SwitchLinc V2 Dimmer 600W [2476D]";
			else if (bytes[1] == 0x02)
				return @"In-LineLinc Dimmer [2475D]";
			else if (bytes[1] == 0x03)
				return @"Icon Switch Dimmer [2876D]";
			else if (bytes[1] == 0x04)
				return @"SwitchLinc V2 Dimmer 1000W [2476DH]";
			else if (bytes[1] == 0x06)
				return @"LampLinc 2-Pin [2456D2]";
			else if (bytes[1] == 0x07)
				return @"Icon LampLinc V2 2-Pin [2456D2]";
			else if (bytes[1] == 0x09)
				return @"KeypadLinc Dimmer [2486D]";
			else if (bytes[1] == 0x0a)
				return @"Icon In-Wall Controller [2886D]";
			else if (bytes[1] == 0x0d)
				return @"SocketLinc [2454D]";
			else if (bytes[1] == 0x13)
				return @"Icon SwitchLinc Dimmer for Lixar/Bell Canada [2676D-B]";
		}
		else if (bytes[0] == 0x02)
		{
			if (bytes[1] == 0x09)
				return @"ApplianceLinc [2456S3]";
			else if (bytes[1] == 0x0a)
				return @"SwitchLinc Relay [2476S]";
			else if (bytes[1] == 0x0b)
				return @"Icon On Off Switch [2876S]";
			else if (bytes[1] == 0x0c)
				return @"Icon Appliance Adapter [2856S3]";
			else if (bytes[1] == 0x0d)
				return @"ToggleLinc Relay [2466S]";
			else if (bytes[1] == 0x0e)
				return @"SwitchLinc Relay Countdown Timer [2476ST]";
			else if (bytes[1] == 0x10)
				return @"In-LineLinc Relay [2475D]";
			else if (bytes[1] == 0x13)
				return @"SwitchLinc Relay Countdown Timer [2476ST]";
			else if (bytes[1] == 0x0e)
				return @"Icon SwitchLinc Relay for Lixar/Bell Canada [2676R-B]";
		}
		else if (bytes[0] == 0x05)
		{
			if (bytes[1] == 0x00)
				return @"Broan SMSC080 Exhaust Fan [2456S3]";
			else if (bytes[1] == 0x01)
				return @"Compacta EZTherm";
			else if (bytes[1] == 0x02)
				return @"Broan SMSC110 Exhaust Fan";
			else if (bytes[1] == 0x03)
				return @"Venstar RF Thermostat Module";
			else if (bytes[1] == 0x04)
				return @"Compacta EZThermx Thermostat";
		}
		else if (bytes[0] == 0x0f)
		{
			if (bytes[1] == 0x04)
				return @"GarageHawk Garage Unit";
			else if (bytes[1] == 0x05)
				return @"GarageHawk Remote Unit";
		}
		
		return [NSString stringWithFormat:@"Unknown Device (0x%02x.0x%02x)", bytes[0], bytes[1]];
	} */

	if ([type length] == 2)
	{
		NSBundle * bundle = nil;
		NSEnumerator * bundleIter = [[NSBundle allFrameworks] objectEnumerator];
		while (bundle = [bundleIter nextObject])
		{	
			NSString * path = [bundle pathForResource:@"Insteon-Devices" ofType:@"plist"];
		
			if (path)
			{
				NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile:path];
			
				if (dict)
				{
					NSString * key = [[NSString stringWithFormat:@"0x%02x 0x%02x", bytes[0], bytes[1]] uppercaseString];
					
					NSDictionary * device = [dict valueForKey:key];

					if (device)
						return [NSString stringWithFormat:@"%@ [%@]", [device valueForKey:@"name"], [device valueForKey:@"model"]];
				}
			}
		}

		return [NSString stringWithFormat:@"Unknown Device (0x%02x.0x%02x)", bytes[0], bytes[1]];
	}

	return @"Unknown Device";
}

@end
