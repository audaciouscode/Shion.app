//
//  ASAggregateCommand.m
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

#import "ASAggregateCommand.h"

#define COMMAND_LIST @"Command List"

@implementation ASAggregateCommand

- (void) addCommand:(ASCommand *) command
{
	NSMutableArray * commandList = (NSMutableArray *) [self valueForKey:COMMAND_LIST];
	
	if (commandList == nil)
	{
		commandList = [NSMutableArray array];
		[self setValue:commandList forKey:COMMAND_LIST];
	}
	
	[commandList addObject:command];
}

- (NSArray *) commands
{
	return (NSArray *) [self valueForKey:COMMAND_LIST];
}

@end
