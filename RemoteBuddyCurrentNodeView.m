//
//  RemoteBuddyCurrentNodeView.m
//  Shion
//
//  Created by Chris Karr on 9/20/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "RemoteBuddyCurrentNodeView.h"
#import "NSBezierPathRoundRects.h"

@implementation RemoteBuddyCurrentNodeView

- (id)initWithFrame:(NSRect)frame {

    if (self = [super initWithFrame:frame]) 
	{
		message = @"";
    }

    return self;
}

- (void) setMessage:(NSString *) newMessage
{
	if (message != nil)
		[message release];
	
	message = [newMessage retain];

	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect 
{
	float fontSize = 96;
	float radius = 50;

	NSWindow * parent = [self window];
	NSRect windowRect = [parent frame];
	
	[NSApp activateIgnoringOtherApps:YES];
	
	NSTextStorage * textStorage = [[[NSTextStorage alloc] initWithString:message] autorelease];
	NSTextContainer * textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(windowRect.size.width - (2 * radius), windowRect.size.height - (2 * radius))] autorelease];
	NSLayoutManager * layoutManager = [[[NSLayoutManager alloc] init] autorelease];

	// Text size...
	
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];
	
	[textStorage addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:fontSize] range:NSMakeRange(0, [textStorage length])];
	[textContainer setLineFragmentPadding:0.0];
	
	[layoutManager glyphRangeForTextContainer:textContainer];
	
	NSSize textSize = [layoutManager usedRectForTextContainer:textContainer].size;
	
	NSRect textFrame = NSMakeRect(((windowRect.size.width - textSize.width) / 2) - radius,
								  ((windowRect.size.height - textSize.height) / 2) - radius,
								  textSize.width + (2 * radius), textSize.height + (2 * radius));
	
	NSBezierPath * rectPath = [NSBezierPath bezierPathWithRoundRectInRect:textFrame radius:radius];
	[[NSColor colorWithDeviceRed:.239215 green:.239215 blue:.239215 alpha:.77647] setFill];
	[rectPath fill];

	textFrame.size.width -= (radius * 2);
	textFrame.size.height -= (radius * 2);
	textFrame.origin.y += radius;
	textFrame.origin.x += radius;
	
	NSDictionary * attrs = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSFont systemFontOfSize:fontSize], NSFontAttributeName,
							[NSColor whiteColor], NSForegroundColorAttributeName,
							nil];
	
	[message drawInRect:textFrame withAttributes:attrs];
	
}

@end
