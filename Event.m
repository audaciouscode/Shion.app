//
//  Event.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Event.h"

#define DATE @"date"
#define SOURCE @"source"
#define INITIATOR @"initiator"
#define DESCRIPTION @"description"
#define TYPE @"type"
#define VALUE @"value"


@implementation Event

+ (Event *) eventWithType:(NSString *) type source:(NSString *) source initiator:(NSString *) initiator 
			  description:(NSString *) description value:(id) value date:(NSDate *) date
{
	Event * event = [Event dictionary];

	[event setValue:date forKey:DATE];
	[event setValue:source forKey:SOURCE];
	[event setValue:initiator forKey:INITIATOR];
	[event setValue:description forKey:DESCRIPTION];
	[event setValue:value forKey:VALUE];
	[event setValue:type forKey:TYPE];
	
	return event;
}

- (NSDate *) date
{
	return [self valueForKey:DATE];
}

- (NSString *) description
{
	return [self valueForKey:DESCRIPTION];
}

- (NSString *) source;
{
	return [self valueForKey:SOURCE];
}

- (NSString *) initiator;
{
	return [self valueForKey:INITIATOR];
}

- (NSString *) type;
{
	return [self valueForKey:TYPE];
}

- (id) value;
{
	return [self valueForKey:VALUE];
}

@end
