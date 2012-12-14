//
//  ASX10Controller.h
//  Shion Framework
//
//  Created by Chris Karr on 3/31/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASDeviceController.h"

@interface ASX10Controller : ASDeviceController 
{
	unsigned char currentX10Address;
	unsigned char currentX10Command;
}

- (void) processX10Message:(NSData *) message;

- (unsigned char) xtenCommandByteForDevice:(ASDevice *)device command:(ASCommand *) command;

@end
