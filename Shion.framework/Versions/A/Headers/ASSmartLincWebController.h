//
//  ASSmartLincWebController.h
//  Shion Framework
//
//  Created by Chris Karr on 2/4/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASDeviceController.h"

@interface ASSmartLincWebController : ASDeviceController 
{
	NSString * _host;
	NSTimer * timer;

	NSTimer * bufferTimer;
	
	NSMutableData * bufferData;
	
	NSMutableString * lastString;
	
	NSMutableArray * pendingCommands;
}

- (ASSmartLincWebController *) initWithHost:(NSString *) host;
- (ASDevice *) deviceWithAddress:(NSData *) addressBytes;

@end
