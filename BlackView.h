//
//  BlackView.h
//  Shion
//
//  Created by Chris Karr on 3/10/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PresenceTimeline.h"

@interface BlackView : NSView 
{
	IBOutlet NSObjectController * objectController;
	NSTimer * refreshTimer;
	
	NSMutableDictionary * timelineCache;
}

- (void) drawTimeline:(PresenceTimeline *) timeline start:(NSTimeInterval) start end:(NSTimeInterval) end inRect:(NSRect) rect;
- (void) drawTimeline:(PresenceTimeline *) timeline start:(NSTimeInterval) start end:(NSTimeInterval) end inRect:(NSRect) rect object:(id) object;
- (void) drawTimeline:(PresenceTimeline *) timeline start:(NSTimeInterval) start end:(NSTimeInterval) end inRect:(NSRect) rect object:(id) object highlighted:(BOOL) highlight;

- (NSColor *) primaryColorForObject:(id) object;
- (void) drawChartForEvents:(NSArray *) events;
- (void) drawChartForEvents:(NSArray *) events days:(int) days;

@end
