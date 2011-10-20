//
//  XMPPUserActivityCommand.h
//  Shion
//
//  Created by Chris Karr on 8/10/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPPIQCommand.h"

@interface XMPPUserActivityCommand : XMPPIQCommand 
{
	NSString * activityString;
}

- (void) setActivity:(NSString *) activity;

@end
