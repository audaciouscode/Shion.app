//
//  GraphInterfaceNode.m
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "GraphInterfaceNode.h"


@implementation GraphInterfaceNode

- (id) initWithInterface:(GraphInterface *) myInterface
{
	if (self = [super init])
	{
		autoAction = nil;

		previousAction = nil;
		nextAction = nil;
		okAction = nil;
		cancelAction = nil;
		
		visitCount = 0;
		
		interface = [myInterface retain];
	}
	
	return self;
}

- (id) interface
{
	return interface;
}

// TODO: dealloc

- (void) setNextAction:(GraphInterfaceAction *) action
{
	if (nextAction != nil)
		[nextAction release];

	nextAction = [action retain];
}

- (void) setPreviousAction:(GraphInterfaceAction *) action
{
	if (previousAction != nil)
		[previousAction release];

	previousAction = [action retain];
}

- (void) setAutoAction:(GraphInterfaceAction *) action
{
	if (autoAction != nil)
		[autoAction release];

	autoAction = [action retain];
}

- (void) setCancelAction:(GraphInterfaceAction *) action
{
	if (cancelAction != nil)
		[cancelAction release];

	cancelAction = [action retain];
}

- (void) setOkAction:(GraphInterfaceAction *) action
{
	if (okAction != nil)
		[okAction release];

	okAction = [action retain];
}

- (GraphInterfaceAction *) nextAction
{
	return nextAction;
}

- (GraphInterfaceAction *) previousAction
{
	return previousAction;
}

- (GraphInterfaceAction *) autoAction;
{
	return autoAction;
}

- (GraphInterfaceAction *) cancelAction
{
	return cancelAction;
}

- (GraphInterfaceAction *) okAction
{
	return okAction;
}



@end
