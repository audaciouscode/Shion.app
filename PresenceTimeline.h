//
//  PresenceTimeline.h
//  Shion
//
//  Created by Chris Karr on 4/11/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PresenceTimeline : NSObject 
{
	NSTimeInterval start;
	NSTimeInterval end;

	unsigned int index;
	unsigned int length;
	
	NSMutableArray * dates;
	NSMutableArray * presences;
	
	float * values;
}

- (id) initWithStart:(NSTimeInterval) startInterval end:(NSTimeInterval) endInterval initialValue:(float) value;

- (void) setValue:(float) value atInterval:(NSTimeInterval) interval;
- (void) setValue:(float) value atInterval:(NSTimeInterval) interval duration:(NSTimeInterval) duration;

- (double) averageForStart:(NSTimeInterval) startInterval end:(NSTimeInterval) endInterval;

@end
