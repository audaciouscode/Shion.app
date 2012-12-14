//
//  ASSerialPortAddress.m
//  Shion Framework
//
//  Created by Chris Karr on 2/5/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import "ASSerialPortAddress.h"


@implementation ASSerialPortAddress

- (void) setPort:(NSString *) port
{
	if (_port != nil)
		[_port release];
	
	_port = [port retain];
}

- (id) getAddress
{
	return _port;
}


@end
