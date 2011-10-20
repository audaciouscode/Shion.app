//
//  Command.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "Command.h"


@implementation Command

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	NSString * string = [NSString stringWithFormat:@"Unimplemented command: %@. (Implement in subclasses.)", [[self class] description]];
	
	[result setValue:string forKey:CMD_RESULT_DESC];
	[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	
	return result;
}

@end
