//
//  GraphInterface.m
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "GraphInterface.h"
#import "GraphInterfaceNode.h"

@implementation GraphInterface

- (void) init;
{
	if (self = [super init])
	{
		home = nil;
		current = nil;
		waiting = NO;
	}
}

- (void) awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(action:) name:GRAPH_ACTION_OK object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(action:) name:GRAPH_ACTION_CANCEL object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(action:) name:GRAPH_ACTION_NEXT object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(action:) name:GRAPH_ACTION_PREVIOUS object:nil];
}	

- (void) releaseWait:(NSTimer *) theTimer
{
	waiting = NO;
}

- (void) action:(NSNotification *) theNote
{
	if (waiting)
		return;
	
	NSString * action = [theNote name];
	
	if ([action isEqual:GRAPH_ACTION_OK])
		[self executeAction:OK_ACTION];
	else if ([action isEqual:GRAPH_ACTION_CANCEL])
		[self executeAction:CANCEL_ACTION];
	else if ([action isEqual:GRAPH_ACTION_NEXT])
		[self executeAction:NEXT_ACTION];
	else if ([action isEqual:GRAPH_ACTION_PREVIOUS])
		[self executeAction:PREVIOUS_ACTION];
	else
		NSLog (@"unknown command: %@", [theNote name]);
	
	throttle = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(releaseWait:) userInfo:nil repeats:NO];
	waiting = YES;
}

- (void) dealloc
{
	if (home != nil)
		[home release];

	if (current != nil)
		[current release];

	[super dealloc];
}

- (void) setHome:(id) newHome
{
	if (home != nil)
		[home release];
	
	home = [newHome retain];
	
	[self advanceTo:home];
}

- (void) setCurrent:(id) newCurrent
{
	if (current != nil)
		[current release];
	
	current = [newCurrent retain];
}

- (void) advanceTo:(id) location
{
	GraphInterfaceNode * locationNode = (GraphInterfaceNode *) location;

	if ([locationNode interface] == self)
	{
		[self setCurrent:locationNode];
		[self executeAction:AUTO_ACTION];
	}
	else
	{
		// TODO: error?
	}
}

- (void) executeAction:(unsigned char) action
{
	if (current != nil)
	{
		switch (action) {
			case OK_ACTION:
				[[current okAction] execute];
				break;
			case CANCEL_ACTION:
				[[current cancelAction] execute];
				break;
			case NEXT_ACTION:
				[[current nextAction] execute];
				break;
			case PREVIOUS_ACTION:
				[[current previousAction] execute];
				break;
			case AUTO_ACTION:
				[[current autoAction] execute];
				break;
			default:
				break;
		}
	}
	else 
	{
		// TODO: Error?
	}
}

@end
