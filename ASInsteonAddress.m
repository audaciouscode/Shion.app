//
//  ASInsteonAddress.m
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

#import "ASInsteonAddress.h"


@implementation ASInsteonAddress

+ (NSData *) addressForString:(NSString *) addressString
{
	if (addressString == nil || [addressString isEqual:@""] || [addressString length] != 6)
		return nil;
	
	NSString * a = [addressString substringWithRange:NSMakeRange (0, 2)];
	NSString * b = [addressString substringWithRange:NSMakeRange (2, 2)];
	NSString * c = [addressString substringWithRange:NSMakeRange (4, 2)];
	
	unsigned char aHex = (unsigned char) strtol ([a cStringUsingEncoding:NSASCIIStringEncoding], nil, 0x10);
	unsigned char bHex = (unsigned char) strtol ([b cStringUsingEncoding:NSASCIIStringEncoding], nil, 0x10);
	unsigned char cHex = (unsigned char) strtol ([c cStringUsingEncoding:NSASCIIStringEncoding], nil, 0x10);
	
	unsigned char addressBytes[] = {aHex, bHex, cHex};
	
	return [NSData dataWithBytes:addressBytes length:3];
}

- (void) setAddress:(NSData *) newAddress
{
	if (address != nil)
		[address release];
	
	address = [newAddress retain];
}

- (void) dealloc
{
	if (address != nil)
		[address release];

	[super dealloc];
}

- (id) getAddress
{
	return address;
}

- (NSString *) description
{
	NSMutableString * desc = [NSMutableString string];
	
	unsigned char * bytes = (unsigned char *) [address bytes];
	
	int i = 0;
	for (i = 0; i < [address length]; i++)
		[desc appendFormat:@"%02x", bytes[i]];
	
	return desc;
}

@end
