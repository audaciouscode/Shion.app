//
//  LogManager.h
//  Shion
//
//  Created by Chris Karr on 2/9/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define LOG_TYPE @"Log Type"
#define LOG_DESCRIPTION @"Log Description"

#define LOG_NOTIFICATION @"Log Notification"
#define LOG_LOCAL_COMMAND @"Log: Local Command"
#define LOG_NETWORK_COMMAND @"Log: Network Command"
#define LOG_EVENT_ASSOCIATED @"Log: Event Associated"
#define LOG_EVENT_UNASSOCIATED @"Log: Event Unassociated"
#define LOG_EXTERNAL_X10 @"Log: External X10"
#define LOG_EXTERNAL_EVENTS @"Log: External Notifications"
#define LOG_DEVICE_TRAFFIC @"Log: Raw Device Traffic"

@interface LogManager : NSObject 
{
	NSMutableArray * pendingEvents;
	NSTimer * logTimer;
}

+ (LogManager *) sharedInstance;
- (NSString *) analyticsFolder;


@end
