//
//  ASVirtualDeviceController.m
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

#import "ASVirtualDeviceController.h"
#import "ASVirtualAddress.h"

#import "ASContinuousDevice.h"
#import "ASCommands.h"

@implementation ASVirtualDeviceController

- (BOOL) acceptsCommand: (ASCommand *) command;
{
	ASAddress * deviceAddress = [[command getDevice] getAddress];
	
	if ([deviceAddress isMemberOfClass:[ASVirtualAddress class]])
		return YES;
		
	return NO;
}

- (void) refresh
{
	ASAddress * deviceAddress = [[ASVirtualAddress alloc] init];
	
	ASDevice * device = [[ASDevice alloc] init];
	[device setAddress:deviceAddress];
	[devices addObject:device];
	[device release];

	device = [[ASToggleDevice alloc] init];
	[device setAddress:deviceAddress];
	[devices addObject:device];
	[device release];

	device = [[ASContinuousDevice alloc] init];
	[device setAddress:deviceAddress];
	[devices addObject:device];
	[device release];
	
	[deviceAddress release];
}

- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind
{
	ASCommand * command = nil;
	
	if ([[device getAddress] isMemberOfClass:[ASVirtualAddress class]])
		command = [super commandForDevice:device kind:commandKind];
	
	return command;
}

- (void) executeNextCommand
{
	if ([commandQueue count] > 0)
	{
		ASCommand * command = [commandQueue objectAtIndex:0];
		ASDevice * device = [command getDevice];
		
		if ([command isMemberOfClass:[ASStatusCommand class]])
		{
			[device setValue:DEVICE_AVAILABLE forKey:STATUS];
			[commandQueue removeObject:command];
		}
		else if ([device isKindOfClass:[ASToggleDevice class]])
		{
			if ([command isMemberOfClass:[ASActivateCommand class]])
			{
				[((ASToggleDevice *) device) setActive:YES];
				[commandQueue removeObject:command];
			}
			else if ([device isKindOfClass:[ASContinuousDevice class]])
			{
				if ([command isMemberOfClass:[ASSetLevelCommand class]])
				{
					[((ASContinuousDevice *) device) setLevel:[((ASSetLevelCommand *) command) level]];
					[commandQueue removeObject:command];
				}
				else if ([command isMemberOfClass:[ASIncreaseCommand class]])
				{
					float level = [[((ASContinuousDevice *) device) level] floatValue] + 0.1;
					
					[((ASContinuousDevice *) device) setLevel:[NSNumber numberWithFloat:level]];
					[commandQueue removeObject:command];
				}
				else if ([command isMemberOfClass:[ASDecreaseCommand class]])
				{
					float level = [[((ASContinuousDevice *) device) level] floatValue] - 0.1;
					
					[((ASContinuousDevice *) device) setLevel:[NSNumber numberWithFloat:level]];
					[commandQueue removeObject:command];
				}
			}
		}
	}
}

@end
