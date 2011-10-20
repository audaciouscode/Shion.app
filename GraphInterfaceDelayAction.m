//
//  GraphInterfaceDelayAction.m
//  Shion
//
//  Created by Chris Karr on 9/20/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "GraphInterfaceDelayAction.h"


@implementation GraphInterfaceDelayAction

- (void) execute
{
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
}

@end
