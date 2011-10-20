//
//  ShionTriggerPopUpButton.m
//  Shion
//
//  Created by Chris Karr on 5/29/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import "ShionTriggerPopUpButton.h"

@implementation ShionTriggerPopUpButton

- (void) mouseDown:(NSEvent *) theEvent
{
	[super mouseDown:theEvent];

//	[self selectItemAtIndex:2];
}

- (void) awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(itemSelected:)
												 name:NSMenuDidSendActionNotification 
											   object:[self menu]];
}

- (void) itemSelected:(NSNotification *) theNote
{
	NSMenuItem * item = [[theNote userInfo] valueForKey:@"MenuItem"];

	NSString * value = [item title];
	
	if ([value isEqual:@"Snapshot"])
		[[NSNotificationCenter defaultCenter] postNotificationName:NEED_SNAPSHOT object:self];
	else if ([value isEqual:@"Script"])
		[[NSNotificationCenter defaultCenter] postNotificationName:NEED_SCRIPT object:self];
}

@end
