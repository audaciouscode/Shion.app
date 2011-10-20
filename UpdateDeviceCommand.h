//
//  UpdateDeviceCommand.h
//  Shion
//
//  Created by Chris Karr on 3/4/10.
//  Copyright 2010 Audacious Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPIQCommand.h"

@interface UpdateDeviceCommand : XMPPIQCommand 
{
	NSArray * _devices;
	NSDictionary * _dictionary;
}

- (void) setDevices:(NSArray *) devices;
- (void) setDictionary:(NSDictionary *) dictionary;

@end
