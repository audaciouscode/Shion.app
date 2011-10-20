//
//  DialogManager.h
//  Shion
//
//  Created by Chris Karr on 8/1/09.
//  Copyright 2009 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Command.h"

@interface DialogManager : NSObject 
{
	IBOutlet NSArrayController * devices;
	IBOutlet NSArrayController * snapshots;
}

+ (DialogManager *) sharedInstance;

- (Command *) commandForString:(NSString *) userText;

@end
