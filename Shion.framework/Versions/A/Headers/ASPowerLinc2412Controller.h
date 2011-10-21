//
//  ASPowerLincModemController.h
//  Shion Framework
//
//  Created by Chris Karr on 2/19/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASPowerLincController.h"
#import "ASCommand.h"
#import "ASInsteonAddress.h"

@interface ASPowerLinc2412Controller : ASPowerLincController 
{
	BOOL inited;
	BOOL ready;
	
	NSMutableData * buffer;
	NSTimer * wakeup;
	NSTimer * readTimer;
	NSFileHandle * serialPort;
	NSString * bsdPath;

	ASCommand * currentCommand;
}

- (ASPowerLinc2412Controller *) initWithPath:(NSString *) path;
+ (ASPowerLinc2412Controller *) controllerWithPath:(NSString *) path;

- (void) startAllLink;
- (void) cancelAllLink;

@end
