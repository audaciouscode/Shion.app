//
//  NotificationManager.h
//  Shion
//
//  Created by Chris Karr on 1/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl-WithInstaller/Growl.h>

#define FETCHING_STATUS NSLocalizedString(@"Fetching Device Status", nil)
#define DEVICE_STATE_CHANGED NSLocalizedString(@"Device State Changed", nil)
#define SCHEDULED_ITEM NSLocalizedString(@"Scheduled Item", nil)
#define REMOTE_STATUS NSLocalizedString(@"Remote Control Status", nil)
#define ONLINE_STATUS NSLocalizedString(@"Online Service Status", nil)
#define EVENT_NOTE NSLocalizedString(@"Shion Events", nil)
#define X10_NOTE NSLocalizedString(@"X10 Events", nil)
#define HARDWARE_NOTE NSLocalizedString(@"Hardware Error Events", nil)
#define REMOTE_CLIENT_NOTE NSLocalizedString(@"Remote Client Events", nil)
#define MOTION_STATUS NSLocalizedString(@"Motion Detector Status", nil)
#define XMPP_COMMAND NSLocalizedString(@"Remote XMPP Command", nil)
#define INCOMING_PHONE_CALL NSLocalizedString(@"Incoming Phone Call", nil)

#define NOTIFICATION_MSG @"Notification Message"
#define NOTIFICATION_TITLE @"Notification Title"
#define NOTIFICATION_MESSAGE @"Notification Message Text"
#define NOTIFICATION_TYPE @"Notification Type"
#define NOTIFICATION_ICON @"Notification Icon"

@interface NotificationManager : NSObject <GrowlApplicationBridgeDelegate>
{

}

+ (NotificationManager *) sharedInstance;

- (void) showMessage:(NSString *) message title:(NSString *) title icon:(NSImage *) icon type:(NSString *) type;

@end
