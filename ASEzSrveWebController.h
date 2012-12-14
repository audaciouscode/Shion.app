//
//  ASEzSrveWebController.h
//  Shion Framework
//
//  Created by Chris Karr on 2/15/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASDeviceController.h"


@interface ASEzSrveWebController : ASDeviceController
{
	NSString * _host;
	
	NSTimer * _refreshTimer;
	
	NSInputStream * _input;
	NSOutputStream * _output;
	
	BOOL ready;
	NSMutableSet * knownDevices;
	NSMutableData * readData;
}

- (ASEzSrveWebController *) initWithHost:(NSString *) host;
+ (NSString *) findController;

@end
