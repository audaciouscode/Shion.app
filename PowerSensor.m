//
//  PowerSensor.m
//  Shion
//
//  Created by Chris Karr on 4/1/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import "PowerSensor.h"
#import "EventManager.h"

@implementation PowerSensor

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Power Sensor" forKey:TYPE];
	}
	
	return self;
}

- (BOOL) isActive
{
	NSManagedObject * e = [[EventManager sharedInstance] lastUpdateForIdentifier:[self identifier] event:@"device"];
	
	if (e != nil)
	{
		if ([[e valueForKey:@"value"] intValue] > 0)
			return YES;
	}
	
	return NO;
}

@end
