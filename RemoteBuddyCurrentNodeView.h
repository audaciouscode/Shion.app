//
//  RemoteBuddyCurrentNodeView.h
//  Shion
//
//  Created by Chris Karr on 9/20/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RemoteBuddyCurrentNodeView : NSView 
{
	NSString * message;
}

- (void) setMessage:(NSString *) newMessage;

@end
