//
//  ListSnapshotsCommand.m
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "ListSnapshotsCommand.h"
#import "Snapshot.h"
#import "SnapshotManager.h"

@implementation ListSnapshotsCommand

- (NSDictionary *) execute
{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	NSArray * snapshots = [[SnapshotManager sharedInstance] snapshots]; 
	
	NSMutableString * string = [NSMutableString string];
	
	if ([snapshots count] > 0)
	{
		[string appendFormat:@"There are %d snapshots available. They are:", [snapshots count]];
		
		NSMutableArray * mySnaps = [NSMutableArray array];
		
		NSEnumerator * iter = [snapshots objectEnumerator];
		Snapshot * snap = nil;
		while (snap = [iter nextObject])
		{
			[string appendFormat:@"\n%@", [snap name]];
			
			NSDictionary * resultSnap = [NSDictionary dictionaryWithDictionary:snap];
			[mySnaps addObject:resultSnap];
		}
		
		[result setValue:mySnaps forKey:CMD_RESULT_VALUE];
	}
	else
		[string appendString:@"There are no snapshots present. Perhaps you would like to set up a few?"];
	
	
	[result setValue:string forKey:CMD_RESULT_DESC];
	[result setValue:[NSNumber numberWithBool:YES] forKey:CMD_SUCCESS];
	
	return result;
}

@end
