//
//  AppDelegate.h
//  Shion
//
//  Created by Chris Karr on 12/21/08.
//  Copyright 2008 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <HockeySDK/HockeySDK.h>

@interface AppDelegate : NSObject<BITCrashReportManagerDelegate>
{
	IBOutlet NSMenu * menu;
	IBOutlet NSMenuItem * favorites;
	NSStatusItem * menuItem;
	
	NSTimer * saveTimer;
}

- (IBAction) troubleshoot:(id) sender;
- (IBAction) visitWebSite:(id) sender;
- (IBAction) moreDevices:(id) sender;
- (IBAction) showTips:(id) sender;

- (void) setStatusError:(BOOL) error;

- (void) refreshFavorites;

@end
