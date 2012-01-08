//
//  EventManager.h
//  Shion
//
//  Created by Chris Karr on 4/7/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EVENT_LIST @"event_list"

@interface EventManager : NSObject 
{
	NSWindowController * windowController;
	IBOutlet NSWindow * window;
	NSMutableDictionary * cache;
	NSTimer * cleanupTimer;
	
	NSMutableDictionary * _timelineCache;

	NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
	
	BOOL dirty;
}

+ (EventManager *) sharedInstance;

- (NSManagedObjectContext *) managedObjectContext;

- (NSManagedObject *) createEvent:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			description:(NSString *) description value:(NSString *) value;

- (NSManagedObject *) createEvent:(NSString *) type source:(NSString *) sourceId initiator:(NSString *) initiator 
			description:(NSString *) description value:(NSString *) value match:(BOOL) matchCheck;

- (NSArray *) events;
- (NSManagedObject *) lastUpdateForIdentifier:(NSString *) identifier event:(NSString *) eventType;

- (void) saveEvents;

- (NSArray *) eventsForIdentifier:(NSString *) identifier;
- (NSArray *) eventsForIdentifier:(NSString *) identifier event:(NSString *) eventType;

- (NSArray *) eventsTree;
- (NSMutableDictionary *) timelineCache;

@end
