//
//  ASCommand.h
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
#import "ASDevice.h"

#define COMMAND_DATE @"Command Date"

@interface ASCommand : NSObject 
{
	ASDevice * commandDevice;
	NSMutableDictionary * properties;
}

- (id) initWithDevice:(ASDevice *) device;

- (ASDevice *) getDevice;
- (void) setDevice:(ASDevice *) device;

- (void) setValue:(NSObject *) value forKey:(NSString *) key;
- (id) valueForKey:(NSString *) key;

@end
