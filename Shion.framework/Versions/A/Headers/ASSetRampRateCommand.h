//
//  ASSetRampRateCommand.h
//  Shion Framework
//
//  Created by Chris Karr on 8/19/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ASCommand.h"

@interface ASSetRampRateCommand : ASCommand 
{
	NSNumber * rate;
}

- (void) setRate:(NSNumber *) rate;
- (NSNumber *) rate;

@end
