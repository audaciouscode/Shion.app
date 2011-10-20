//
//  GraphInterfaceNode.h
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GraphInterfaceAction.h"
#import "GraphInterface.h"

@interface GraphInterfaceNode : NSObject 
{
	GraphInterfaceAction * previousAction;
	GraphInterfaceAction * nextAction;
	GraphInterfaceAction * autoAction;
	GraphInterfaceAction * okAction;
	GraphInterfaceAction * cancelAction;
	
	unsigned int visitCount;
	
	NSString * description;
	
	GraphInterface * interface;
}

- (void) setNextAction:(GraphInterfaceAction *) action;
- (void) setPreviousAction:(GraphInterfaceAction *) action;
- (void) setAutoAction:(GraphInterfaceAction *) action;
- (void) setCancelAction:(GraphInterfaceAction *) action;
- (void) setOkAction:(GraphInterfaceAction *) action;

- (GraphInterfaceAction *) nextAction;
- (GraphInterfaceAction *) previousAction;
- (GraphInterfaceAction *) autoAction;
- (GraphInterfaceAction *) cancelAction;
- (GraphInterfaceAction *) okAction;

- (id) initWithInterface:(GraphInterface *) myInterface;
- (id) interface;

@end
