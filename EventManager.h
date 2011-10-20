//
//  EventManager.h
//  Shion
//
//  Created by Chris Karr on 4/7/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Event.h"

#define EVENT_LIST @"event_list"

@interface EventManager : NSObject 
{
	NSMutableArray * events;
	NSWindowController * windowController;
	IBOutlet NSWindow * window;
	NSMutableDictionary * cache;
	NSTimer * cleanupTimer;
	
	BOOL dirty;
}

+ (EventManager *) sharedInstance;

- (Event *) createEvent:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			description:(NSString *) description value:(id) value;

- (Event *) createEvent:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			description:(NSString *) description value:(id) value match:(BOOL) matchCheck;

- (NSArray *) events;
- (Event *) lastUpdateForIdentifier:(NSString *) identifier event:(NSString *) eventType;

- (void) saveEvents;

- (NSArray *) eventsForIdentifier:(NSString *) identifier;
- (NSArray *) eventsForIdentifier:(NSString *) identifier event:(NSString *) eventType;

- (NSArray *) eventsTree;

@end
