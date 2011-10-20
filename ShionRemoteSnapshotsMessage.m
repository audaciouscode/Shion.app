//
//  ShionRemoteSnapshotsMessage.m
//  Shion
//
//  Created by Chris Karr on 10/14/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "ShionRemoteSnapshotsMessage.h"
#import "SnapshotDictionary.h"
#import "ShionRemoteDevicesMessage.h"
#import "AppDelegate.h"
#import "Shion.h"

@implementation ShionRemoteSnapshotsMessage

- (NSXMLElement *) responseElement
{
	// AppDelegate * delegate = [NSApp delegate];
	NSArray * snapshots = nil; // [delegate systemPropertyForName:@"snapshots"];
	
	NSXMLElement * snapshotsMessage = [NSXMLElement elementWithName:@"snapshots"];
	[snapshotsMessage addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"shion:remote-control"]];

	NSEnumerator * snapsIter = [snapshots objectEnumerator];
	SnapshotDictionary * snap = nil;
	while (snap = [snapsIter nextObject])
	{
		NSXMLElement * item = [NSXMLElement elementWithName:@"snapshot"];
		[item setAttributesAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:[snap valueForKey:SNAPSHOT_NAME], @"name", 
										 [snap valueForKey:SNAPSHOT_ID], @"id", nil]];

		NSArray * devices = [snap valueForKey:SNAPSHOT_DEVICES];
		
		NSEnumerator * iter = [devices objectEnumerator];
		NSDictionary * dict = nil;
		
		while (dict = [iter nextObject])
			[item addChild:[ShionRemoteDevicesMessage elementForDevice:dict]];
			
		[snapshotsMessage addChild:item];
	}
	
	return snapshotsMessage;
}	

- (NSXMLElement *) errorElement
{
	return nil;
}	

@end
