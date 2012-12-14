//
//  ASCM15AUSBController.h
//  Shion Framework
//
//  Created by Chris Karr on 1/1/09.
//  Copyright 2009 Audacious Software. 
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
#import "ASX10Controller.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/usb/IOUSBLib.h>
#include <IOKit/IOCFPlugIn.h>

@interface ASCM15AUSBController : ASX10Controller 
{
	IOUSBInterfaceInterface ** controllerUSB;
	NSTimer * wakeup;
}

+ (ASCM15AUSBController *) findController;
- (ASCM15AUSBController *) initWithUSB:(IOUSBInterfaceInterface**) usb;

- (IOUSBInterfaceInterface**) getUSB;
- (void) setUSB: (IOUSBInterfaceInterface**) usb;
- (void) transmitBytes;

- (void) sendBytes:(NSData *) bytes;




@end
