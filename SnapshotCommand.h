//
//  SnapshotCommand.h
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Command.h"

#import "Snapshot.h"

@interface SnapshotCommand : Command 
{
	Snapshot * snapshot;
}

- (void) setSnaphot:(Snapshot *) newSnapshot;

@end
