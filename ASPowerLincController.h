//
//  ASPowerLincController.h
//  Shion Framework
//
//  Created by Chris Karr on 2/20/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASX10Controller.h"

@interface ASPowerLincController : ASX10Controller 
{
	NSMutableSet * infoDevices;
	
	unsigned char lastSubcommand;
}

- (void) processStandardInsteonMessage:(NSData *) message;
- (void) processExtendedInsteonMessage:(NSData *) message;

- (ASDevice *) deviceWithAddress:(NSData *) addressBytes;

- (NSData *) insteonDataForDevice: (ASDevice *)device command:(ASCommand *) command value:(NSObject *) value;
- (NSData *) insteonDataForDevice: (ASDevice *)device command:(ASCommand *) command;

- (ASCommand *) commandForDevice:(ASDevice *) device kind:(unsigned int) commandKind;

- (void) setControllerVersion:(NSNumber *) version;
- (void) setControllerAddress:(NSData *) addressData;
@end
