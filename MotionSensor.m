//
//  MotionSensor.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "MotionSensor.h"
#import "EventManager.h"

@implementation MotionSensor

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Motion Sensor" forKey:TYPE];
	}
	
	return self;
}

- (BOOL) detectingMotion
{
	Event * e = [[EventManager sharedInstance] lastUpdateForIdentifier:[self identifier] event:@"device"];
	
	if (e != nil)
	{
		if ([[e value] intValue] > 0)
			return YES;
	}
	
	return NO;
}

@end
