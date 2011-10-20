//
//  ActivateSnapshotCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "ActivateSnapshotCommand.h"
#import "Shion.h"

@implementation ActivateSnapshotCommand

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	if (snapshot != nil)
	{
		NSString * string = [NSString stringWithFormat:@"Activating snapshot %@...", [snapshot valueForKey:SNAPSHOT_NAME]];

		[snapshot execute];

		[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
		[result setValue:string forKey:CMD_RESULT_DESC];
	}
	else
	{
		[result setValue:@"Please specify a snapshot to activate." forKey:CMD_RESULT_DESC];
		[result setValue:[NSNumber numberWithBool:NO] forKey:CMD_SUCCESS];
	}	
	
	return result;
}

@end
