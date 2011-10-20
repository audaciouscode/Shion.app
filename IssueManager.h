//
//  IssueManager.h
//  Shion
//
//  Created by Chris Karr on 4/24/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IssueManager : NSObject 
{
	IBOutlet NSTextField * summary;
	IBOutlet NSTextView * description;
	IBOutlet NSTextField * email;

	IBOutlet NSTextField * progressMessage;
	IBOutlet NSProgressIndicator * progressBar;
	IBOutlet NSPanel * progressPanel;
	
	IBOutlet NSWindow * window;
	
	NSWindowController * windowController;
}

+ (IssueManager *) sharedInstance;

- (IBAction) issueWindow:(id) sender;
- (IBAction) submit:(id) sender;

@end
