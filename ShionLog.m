/*
 *  ShionLog.c
 *  Shion Framework
 *
 *  Created by Chris Karr on 2/9/09.
 *  Copyright 2009 Audacious Software. 
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
 *
 */

#include "ShionLog.h"

void ShionLog (NSString * message, ...)
{
	va_list ap;
	va_start(ap, message);
	
	NSString * desc = [[NSString alloc] initWithFormat:message arguments:ap];

	NSMutableDictionary * logDict = [NSMutableDictionary dictionary];
	[logDict setValue:@"Log: Raw Device Traffic" forKey:@"Log Type"];
	[logDict setValue:desc forKey:@"Log Description"];
	
	[desc release];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"Log Notification" object:nil userInfo:logDict];
	
	va_end(ap);
}	
