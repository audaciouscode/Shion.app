//
//  SnapshotManager.h
//  Shion
//
//  Created by Chris Karr on 4/6/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Snapshot.h"

@interface SnapshotManager : NSObject
{
	NSMutableArray * snapshots;
}

+ (SnapshotManager *) sharedInstance;

- (NSArray *) snapshots;
- (Snapshot *) createSnapshot;
- (void) saveSnapshots;
- (void) removeSnapshot:(Snapshot *) snapshot;
- (Snapshot *) snapshotWithIdentifier:(NSString *) identifier;

@end
