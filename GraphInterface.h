//
//  GraphInterface.h
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define OK_ACTION 0x00
#define CANCEL_ACTION 0x01
#define NEXT_ACTION 0x02
#define PREVIOUS_ACTION 0x03
#define AUTO_ACTION 0x04

#define GRAPH_ACTION_PREVIOUS @"Previous Action"
#define GRAPH_ACTION_NEXT @"Next Action"
#define GRAPH_ACTION_OK @"Ok Action"
#define GRAPH_ACTION_CANCEL @"Cancel Action"

@interface GraphInterface : NSObject 
{
	id home;
	id current;
	
	NSTimer * throttle;
	BOOL waiting;
}

// TODO: better fix for circular references...

- (void) setHome:(id) newHome;
- (void) setCurrent:(id) newCurrent;
- (void) advanceTo:(id) location;

- (void) executeAction:(unsigned char) action;


@end
