//
//  ASSmartLincDirectController.h
//  Shion Framework
//
//  Created by Chris Karr on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ASPowerLincController.h"

@interface ASSmartLincDirectController : ASPowerLincController
{
	NSInputStream * _input;
	NSOutputStream * _output;

	BOOL ready;
	NSMutableData * bufferData;
	NSTimer * wakeup;
	
	ASCommand * currentCommand;
	
	NSString * _host;
}

@end
