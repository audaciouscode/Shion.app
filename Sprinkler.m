//
//  Sprinkler.m
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "Sprinkler.h"

@implementation Sprinkler

- (id) initWithCapacity:(unsigned int) numItems
{
	if (self = [super initWithCapacity:numItems])
	{
		[self setValue:@"Sprinkler" forKey:TYPE];
	}
	
	return self;
}

@end
