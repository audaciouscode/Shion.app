//
//  RemoteBuddyGraphInterface.h
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GraphInterface.h"

@interface RemoteBuddyGraphInterface : GraphInterface
{
	IBOutlet NSArrayController * devicesController;
	IBOutlet NSArrayController * snapshotsController;
	
	IBOutlet NSWindow * speechWindow;
}

- (void) configureWithDevices:(NSArray *) devices snapshots:(NSArray *) snapshots;

@end
