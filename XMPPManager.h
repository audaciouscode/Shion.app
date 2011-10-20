//
//  XMPPManager.h
//  Shion
//
//  Created by Chris Karr on 7/27/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XMPP/XMPP.h>

#import "Event.h"
#import "Device.h"
#import "Camera.h"
#import "Tivo.h"

#define XMPP_NOTIFICATION @"XMPP Notification"

@interface XMPPManager : NSObject 
{	
	int idCount;
	
	XMPPClient * client;
	
	BOOL iconPosted;
	
	NSMutableArray * clientJids;
	NSString * lastStatusString;
}

+ (XMPPManager *) sharedInstance;

- (BOOL) sendEnvironmentToJid:(NSString *) jid;
- (void) updateStatus:(NSString *) status available:(BOOL) available;
- (BOOL) sendEventsForDevice:(NSString *) device toJid:(NSString *) jid;
- (BOOL) sendEventsForDevice:(NSString *) device toJid:(NSString *) jid forDateString:(NSString *) dateString;
- (void) broadcastEvent:(Event *) event forIdentifier:(NSString *) identifier;
- (void) beaconDevice:(Device *) device;

- (void) transmitPhotoList:(NSArray *) photos forCamera:(Camera *) camera;
- (void) transmitPhoto:(NSDictionary *) photoDict forCamera:(Camera *) camera;

- (void) transmitRecordings:(NSArray *) recordings forTivo:(Tivo *) tivo;

@end
