//
//  Device.m
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

#import "ASDevice.h"

@implementation ASDevice

- (ASDevice *) init
{
	if (self = [super init])
		properties = [[NSMutableDictionary alloc] init];

	return self;
}

- (void) dealloc
{
	if (deviceAddress != nil)
		[deviceAddress release];

	[properties release];
	
	[super dealloc];
}

- (void) setAddress:(ASAddress *) address
{
	if (deviceAddress != nil)
		[deviceAddress release];
	
	deviceAddress = [address retain];
}

- (ASAddress *) getAddress
{
	return deviceAddress;
}

- (id) valueForKey:(NSString *) key
{
	return [properties valueForKey:key];
}

- (void) setValue:(NSObject *) value forKey:(NSString *) key
{
	[properties setValue:value forKey:key];
}

- (void) removeValueForKey:(NSString *) key
{
	[properties removeObjectForKey:key];
}

- (NSString *) productCode
{
	return @"FFFF";
}

@end
