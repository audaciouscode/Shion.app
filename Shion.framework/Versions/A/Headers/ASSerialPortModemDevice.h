//
//  ASSerialPortModemDevice.h
//  Shion Framework
//
//  Created by Chris Karr on 2/5/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASDevice.h"

#define RINGING @"Modem: Ringing"
#define CID_NAME @"Modem: CID Name"
#define CID_NUMBER @"Modem: CID Number"

@interface ASSerialPortModemDevice : ASDevice 
{
	NSString * _model;
	NSFileHandle * handle;
}

- (void) setModel:(NSString *) model;
- (void) go;

@end
