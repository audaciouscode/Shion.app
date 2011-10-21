//
//  ASSerialPortAddress.h
//  Shion Framework
//
//  Created by Chris Karr on 2/5/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASAddress.h"

@interface ASSerialPortAddress : ASAddress
{
	NSString * _port;
}

- (void) setPort:(NSString *) port;
@end
