//
//  IssueManager.m
//  Shion
//
//  Created by Chris Karr on 4/24/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import "IssueManager.h"
#import <AddressBook/AddressBook.h>

@implementation IssueManager

static IssueManager * sharedInstance = nil;

+ (IssueManager *) sharedInstance
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedInstance;
}

+ (id) allocWithZone:(NSZone *) zone
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
	
    return nil; //on subsequent allocation attempts return nil
}

- (id) copyWithZone:(NSZone *) zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (unsigned) retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void) release
{
    //do nothing
}

- (id) autorelease
{
    return self;
}

- (id) init
{
	if (self = [super init])
	{
		windowController = [[NSWindowController alloc] initWithWindowNibName:@"IssueWindow" owner:self];
	}
	
	return self;
}

- (IBAction) submit:(id) sender
{
	if ([[summary stringValue] isEqual:@""])
		NSRunAlertPanel(@"Summary Missing", @"Please provide a one-line summary of the issue.", @"OK", nil, nil);
	else
	{
		if ([description string] == nil || [[description string] isEqual:@""])
			[description setString:@"No description provided."];

		[progressBar setIndeterminate:YES];
		[progressBar setUsesThreadedAnimation:YES];
		[progressBar startAnimation:sender];
			
		[progressMessage setStringValue:@"Submitting issue report..."];
			
		[NSApp beginSheet:progressPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:NULL];

		NSMutableString * urlBase = [NSMutableString stringWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"ShionBugEndpoint"]];
		[urlBase appendString:@"?summary="];
		[urlBase appendString:[[summary stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

		[urlBase appendString:@"&description="];
		[urlBase appendString:[[description string] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

		[urlBase appendString:@"&email="];
		[urlBase appendString:[[email stringValue] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

		[urlBase appendString:@"&version="];
		[urlBase appendString:[[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

		NSError * error = nil;
			
		NSData * bug = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlBase] options:0 error:&error];

		[NSApp endSheet:progressPanel];
		[progressPanel orderOut:self];
		[progressBar stopAnimation:sender];
			
		if (error != nil)
			NSRunAlertPanel(@"Error Recording Issue", [error localizedDescription], @"OK", nil, nil);
		else
		{
			NSString * bugId = [NSString stringWithCString:[bug bytes] length:[bug length]];
			
			NSRunInformationalAlertPanel(@"Issue Reported", 
										 [NSString stringWithFormat:@"The issue has been recorded. (id:%@)\n\nThank you for your feedback.",
										  bugId, nil], @"OK", nil, nil);
			[[windowController window] orderOut:sender];
		}
	}
}

- (IBAction) issueWindow:(id) sender
{
	[NSApp activateIgnoringOtherApps:YES];

	[summary setStringValue:@""];
	[description setString:@""];

	ABAddressBook * ab = [ABAddressBook sharedAddressBook];
	ABPerson * me = [ab me];
	ABMultiValue * address = [me valueForKey:kABEmailProperty];
	
	if ([address count] > 0)
		[email setStringValue:[address valueAtIndex:0]];

	[windowController showWindow:sender];

	[window center];
	
	[window makeKeyAndOrderFront:sender];
}

@end
