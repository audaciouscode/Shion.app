//
//  ConsoleManager.h
//  Shion
//
//  Created by Chris Karr on 4/5/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define NAV_TREE @"nav_tree"

@interface ConsoleManager : NSObject 
{
	IBOutlet NSWindow * window;

	IBOutlet NSPanel * addDevicePanel;
	IBOutlet NSPanel * addCameraPanel;
	IBOutlet NSPanel * addSnapshotPanel;
	IBOutlet NSPanel * addTriggerPanel;
	
	NSWindowController * windowController;
	
	IBOutlet NSTreeController * treeController;

	IBOutlet NSBrowser * browser;
	IBOutlet NSTabView * metadataTabs;
	IBOutlet NSTabView * controlTabs;
	
	IBOutlet NSArrayController * snapshots;
	IBOutlet NSArrayController * snapshotDevices;
	
	IBOutlet NSPanel * snapshotsPanel;
	
	IBOutlet NSImageView * mapView;
	
	IBOutlet NSPanel * cameraPanel;

	IBOutlet NSWindow * tipWindow;
	IBOutlet NSImageView * tipImageView;
	IBOutlet NSTextField * tipText;
	
	IBOutlet NSArrayController * phoneCalls;
	
	NSIndexPath * treeIndex;
}

+ (ConsoleManager *) sharedInstance;

- (void) reloadDevices;

- (IBAction) consoleWindow:(id) sender;

- (IBAction) showAddMenu:(id) sender;

- (IBAction) addTrigger:(id) sender;

- (IBAction) addDevice:(id) sender;
- (IBAction) dismissDeviceEditor:(id) sender;
- (IBAction) dismissCameraEditor:(id) sender;

- (IBAction) addSnapshot:(id) sender;
- (IBAction) dismissSnapshotEditor:(id) sender;

- (IBAction) addTrigger:(id) sender;
- (IBAction) dismissTriggerEditor:(id) sender;

- (IBAction) edit:(id) sender;
- (IBAction) remove:(id) sender;
- (IBAction) refresh:(id) sender;
- (IBAction) refreshInfo:(id) sender;

- (IBAction) dismissSnapshotsPanel:(id) sender;
- (IBAction) revealTriggerAction:(id) sender;
- (IBAction) removeDeviceFromSnapshot:(id) sender;

- (IBAction) beacon:(id) sender;

// Trigger methods

- (IBAction) setComputerLocation:(id) sender;

- (void) selectItemWithIdentifier:(NSString *) indentifier;
- (NSIndexPath *) selectionIndexPath;
- (void) setSelectionPath:(NSIndexPath *) indexPath;

- (NSSize) mapSize;

- (IBAction) toggleCameraPanel:(id) sender;

- (IBAction) showTips:(id) sender;
- (IBAction) nextTip:(id) sender;
- (IBAction) closeTips:(id) sender;

@end
