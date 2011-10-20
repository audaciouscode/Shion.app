//
//  GraphInterfaceSpeechAction.m
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "GraphInterfaceSpeechAction.h"
#import "RemoteBuddyCurrentNodeView.h"

static BOOL speechThreadCancelled = NO;
static NSWindow * speechWindow = nil;
static unsigned int captionCount = 0;;

@implementation GraphInterfaceSpeechAction

- (id) init
{
	if (self = [super init])
	{
		speech = nil;
	}

	return self;
}

- (void) dealloc
{
	if (speech != nil)
		[speech release];

	[super dealloc];
}

- (void) setSpeech:(NSString *) newSpeech
{
	if (speech != nil)
		[speech release];
	
	speech = [newSpeech retain];
}

+ (NSWindow *) showCaption:(NSString *) newSpeech
{
	NSRect mainScreenRect = [[NSScreen mainScreen] frame];
	
	NSRect frame = NSMakeRect(mainScreenRect.size.width / 4, mainScreenRect.size.height / 4, mainScreenRect.size.width / 2, mainScreenRect.size.height / 2);
	unsigned int styleMask = NSBorderlessWindowMask;
	NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
	
	if (speechWindow == nil)
	{
		speechWindow = [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
	
		[speechWindow setBackgroundColor:[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0]];
		[speechWindow setOpaque:NO];
	}
	
	NSRect windowRect = [speechWindow frame];
	
	RemoteBuddyCurrentNodeView * view = [[RemoteBuddyCurrentNodeView alloc] initWithFrame:NSMakeRect(0, 0, windowRect.size.width, windowRect.size.height)];
	[view setMessage:newSpeech];
	[speechWindow setContentView:view];
	[view release];

	captionCount += 1;
	
	return speechWindow;
}

- (void) speechThreadMethod:(id) param
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];

	NSNumber * enableSpeech = [defaults valueForKey:@"remote_speech"];
	NSNumber * enableDisplay = [defaults valueForKey:@"remote_display"];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  
	

	NSSpeechSynthesizer * synth = nil;
	
	if (enableSpeech != nil && [enableSpeech boolValue])
	{
		synth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
		[synth startSpeakingString:speech];
	}
	 
	NSWindow * caption = nil;
	
	if (enableDisplay == nil || [enableDisplay boolValue])
	{
		caption = [GraphInterfaceSpeechAction showCaption:speech];
		[caption makeKeyAndOrderFront:self];
	}
	
	if (synth != nil)
	{
		while ([synth isSpeaking] && speechThreadCancelled == NO ) 
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
	else
	{
		// Wait for 2 seconds if no speech... (TODO: make preference?)
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
	}
	
	if (synth != nil)
	{
		if ([synth isSpeaking])
			[synth stopSpeaking];

		[synth autorelease];
	}

	if (caption != nil)
	{
		captionCount -= 1;

		if (captionCount == 0)
			[caption orderOut:self];
	}
	
	
	[pool release];
 }

- (void) execute
{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	
	NSNumber * enable = [defaults valueForKey:@"remote_control"];
	
	if (enable != nil && [enable boolValue])
	{
		if (!speechThreadCancelled)
		{
			speechThreadCancelled = YES;
		
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
		}
	
		speechThreadCancelled = NO;
	
		[NSThread detachNewThreadSelector:@selector(speechThreadMethod:) toTarget:self withObject:speech];
	}
}



@end
