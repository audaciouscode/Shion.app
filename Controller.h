//
//  Controller.h
//  Shion
//
//  Created by Chris Karr on 4/7/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ASDeviceController.h"
#import "Device.h"

@interface Controller : Device 
{
	NSTimer * statusTimer;
	
	float lastStatus;
	
	NSTimer * resetTimer;
	NSTimer * closeTimer;
}

+ (Controller *) controller;

- (void) setDeviceController:(ASDeviceController *) controller;
- (ASDeviceController *) deviceController;

- (float) networkState;

@end
