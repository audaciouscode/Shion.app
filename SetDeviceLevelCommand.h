//
//  SetDeviceLevelCommand.h
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DeviceCommand.h"

@interface SetDeviceLevelCommand : DeviceCommand 
{
	int level;
}

-(void) setLevel:(int) deviceLevel;

@end
