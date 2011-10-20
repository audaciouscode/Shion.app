//
//  GraphInterfaceMoveAction.h
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GraphInterfaceAction.h"
#import "GraphInterfaceNode.h"

@interface GraphInterfaceMoveAction : GraphInterfaceAction 
{
	GraphInterfaceNode * destination;
}

- (void) setDestinationNode:(GraphInterfaceNode *) newDestination;

@end
