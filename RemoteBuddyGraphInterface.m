//
//  RemoteBuddyGraphInterface.m
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import "RemoteBuddyGraphInterface.h"
#import "GraphInterfaceNode.h"
#import "DeviceDictionary.h"
#import "SnapshotDictionary.h"
#import "Shion.h"
#import "GraphInterfaceMoveAction.h"
#import "GraphInterfaceSpeechAction.h"
#import "GraphInterfaceCompoundAction.h"
#import "GraphInterfaceDeviceCommandAction.h"
#import "GraphInterfaceDelayAction.h"

#import "RemoteBuddyDefines.h"

@implementation RemoteBuddyGraphInterface

- (GraphInterfaceNode *) commandsNodeForDevice:(DeviceDictionary *) device cancelAction:(GraphInterfaceAction *) moveOkBackAction
{
	NSString * type = [device valueForKey:SHION_TYPE];
	
	if ([type isEqual:TOGGLE_DEVICE] || [type isEqual:HOUSE] || [type isEqual:CONTINUOUS_DEVICE])
	{
		// Set up activate action...
		
		GraphInterfaceNode * activate = [[GraphInterfaceNode alloc] initWithInterface:self];
		
		GraphInterfaceSpeechAction * sayActivate = [[GraphInterfaceSpeechAction alloc] init];
		[sayActivate setSpeech:[NSString stringWithFormat:@"Activate %@?", [device valueForKey:SHION_NAME]]];
		[activate setAutoAction:sayActivate];
		[sayActivate release];
		
		GraphInterfaceCompoundAction * activateAction = [[GraphInterfaceCompoundAction alloc] init];
		
		GraphInterfaceSpeechAction * sayActivating = [[GraphInterfaceSpeechAction alloc] init];
		[sayActivating setSpeech:[NSString stringWithFormat:@"Activating %@...", [device valueForKey:SHION_NAME]]];
		[activateAction addAction:sayActivating];
		[sayActivating release];
		
		GraphInterfaceDeviceCommandAction * deviceActivate = [[GraphInterfaceDeviceCommandAction alloc] init];
		[deviceActivate setDevice:device];
		[deviceActivate setCommand:GRAPH_ACTIVATE];
		[activateAction addAction:deviceActivate];
		[deviceActivate release];
		
		[activate setOkAction:activateAction];
		[activateAction release];
		
		[activate setCancelAction:moveOkBackAction];
		
		// Set up deactivate action...
		
		GraphInterfaceNode * deactivate = [[GraphInterfaceNode alloc] initWithInterface:self];
		
		GraphInterfaceSpeechAction * sayDeactivate = [[GraphInterfaceSpeechAction alloc] init];
		[sayDeactivate setSpeech:[NSString stringWithFormat:@"Deactivate %@?", [device valueForKey:SHION_NAME]]];
		[deactivate setAutoAction:sayDeactivate];
		[sayDeactivate release];
		
		GraphInterfaceCompoundAction * deactivateAction = [[GraphInterfaceCompoundAction alloc] init];
		
		GraphInterfaceSpeechAction * sayDeactivating = [[GraphInterfaceSpeechAction alloc] init];
		[sayDeactivating setSpeech:[NSString stringWithFormat:@"Deactivating %@...", [device valueForKey:SHION_NAME]]];
		[deactivateAction addAction:sayDeactivating];
		[sayDeactivating release];
		
		GraphInterfaceDeviceCommandAction * deviceDeactivate = [[GraphInterfaceDeviceCommandAction alloc] init];
		[deviceDeactivate setDevice:device];
		[deviceDeactivate setCommand:GRAPH_DEACTIVATE];
		[deactivateAction addAction:deviceDeactivate];
		[deviceDeactivate release];
		
		[deactivate setOkAction:deactivateAction];
		[deactivateAction release];

		GraphInterfaceMoveAction * gotoDeactivate = [[GraphInterfaceMoveAction alloc] init];
		[gotoDeactivate setDestinationNode:deactivate];

		GraphInterfaceMoveAction * gotoActivate = [[GraphInterfaceMoveAction alloc] init];
		[gotoActivate setDestinationNode:activate];
			
		[activate setNextAction:gotoDeactivate];
		[deactivate setPreviousAction:gotoActivate];
		
		[deactivate setCancelAction:moveOkBackAction];

		if ([type isEqual:CONTINUOUS_DEVICE])
		{
			// Brighten
			
			GraphInterfaceNode * brighten = [[GraphInterfaceNode alloc] initWithInterface:self];
			
			GraphInterfaceSpeechAction * sayBrighten = [[GraphInterfaceSpeechAction alloc] init];
			[sayBrighten setSpeech:[NSString stringWithFormat:@"Brighten %@?", [device valueForKey:SHION_NAME]]];
			[brighten setAutoAction:sayBrighten];
			[sayBrighten release];
			
			GraphInterfaceCompoundAction * brightenAction = [[GraphInterfaceCompoundAction alloc] init];
			
			GraphInterfaceSpeechAction * sayBrightening = [[GraphInterfaceSpeechAction alloc] init];
			[sayBrightening setSpeech:[NSString stringWithFormat:@"Brightening %@...", [device valueForKey:SHION_NAME]]];
			[brightenAction addAction:sayBrightening];
			[sayBrightening release];
			
			GraphInterfaceDeviceCommandAction * deviceBrighten = [[GraphInterfaceDeviceCommandAction alloc] init];
			[deviceBrighten setDevice:device];
			[deviceBrighten setCommand:GRAPH_BRIGHTEN];
			[brightenAction addAction:deviceBrighten];
			[deviceBrighten release];
			
			[brighten setOkAction:brightenAction];
			[brightenAction release];

			[brighten setCancelAction:moveOkBackAction];

			GraphInterfaceMoveAction * gotoBrighten = [[GraphInterfaceMoveAction alloc] init];
			[gotoBrighten setDestinationNode:brighten];

			[deactivate setNextAction:gotoBrighten];
			[brighten setPreviousAction:gotoDeactivate];
			
			// Dim
			
			GraphInterfaceNode * dim = [[GraphInterfaceNode alloc] initWithInterface:self];
			
			GraphInterfaceSpeechAction * sayDim = [[GraphInterfaceSpeechAction alloc] init];
			[sayDim setSpeech:[NSString stringWithFormat:@"Dim %@?", [device valueForKey:SHION_NAME]]];
			[dim setAutoAction:sayDim];
			[sayDim release];
			
			GraphInterfaceCompoundAction * dimAction = [[GraphInterfaceCompoundAction alloc] init];
			
			GraphInterfaceSpeechAction * sayDimming = [[GraphInterfaceSpeechAction alloc] init];
			[sayDimming setSpeech:[NSString stringWithFormat:@"Dimming %@...", [device valueForKey:SHION_NAME]]];
			[dimAction addAction:sayDimming];
			[sayDimming release];
			
			GraphInterfaceDeviceCommandAction * deviceDim = [[GraphInterfaceDeviceCommandAction alloc] init];
			[deviceDim setDevice:device];
			[deviceDim setCommand:GRAPH_DIM];
			[dimAction addAction:deviceDim];
			[deviceDim release];
			
			[dim setOkAction:dimAction];
			[dimAction release];

			[dim setCancelAction:moveOkBackAction];

			GraphInterfaceMoveAction * gotoDim = [[GraphInterfaceMoveAction alloc] init];
			[gotoDim setDestinationNode:dim];
			
			[brighten setNextAction:gotoDim];
			[dim setPreviousAction:gotoBrighten];

			[dim setNextAction:gotoActivate];
			[activate setPreviousAction:gotoDim];
		}
		else
		{
			[deactivate setNextAction:gotoActivate];
			[activate setPreviousAction:gotoDeactivate];
		}
		
		[gotoDeactivate release];
		[gotoActivate release];

		[deactivate release];
		return [activate autorelease];
	}

	return nil;
}

- (void) activate:(NSNotification *) theNote
{
	if (home == nil)
		[self configureWithDevices:[devicesController arrangedObjects] snapshots:[snapshotsController arrangedObjects]];
}

- (void) deactivate:(NSNotification *) theNote
{
	// TODO
	NSLog(@"deactivate");
}

- (void) awakeFromNib
{
	NSDistributedNotificationCenter * center = [NSDistributedNotificationCenter defaultCenter];
	
	[center addObserver:self selector:@selector(activate:) name:ACTIVATE_DISTANCE_MODE object:nil];
	[center addObserver:self selector:@selector(deactivate:) name:DEACTIVATE_DISTANCE_MODE object:nil];

	[center addObserver:self selector:@selector(okAction:) name:SHION_REMOTE_BUDDY_OK object:nil];
	[center addObserver:self selector:@selector(cancelAction:) name:SHION_REMOTE_BUDDY_CANCEL object:nil];
	[center addObserver:self selector:@selector(nextAction:) name:SHION_REMOTE_BUDDY_NEXT object:nil];
	[center addObserver:self selector:@selector(previousAction:) name:SHION_REMOTE_BUDDY_PREVIOUS object:nil];

	[super awakeFromNib];
}

- (void) configureWithDevices:(NSArray *) devices snapshots:(NSArray *) snapshots
{
	GraphInterfaceNode * homeNode = [[GraphInterfaceNode alloc] initWithInterface:self];

	GraphInterfaceNode * lastNode = nil;
	GraphInterfaceNode * firstNode = nil;
	
	NSEnumerator * deviceIter = [devices objectEnumerator];
	DeviceDictionary * device = nil;
	while (device = [deviceIter nextObject])
	{
		NSString * type = [device valueForKey:SHION_TYPE];
		
		if ([type isEqual:CONTINUOUS_DEVICE] || [type isEqual:TOGGLE_DEVICE] || [type isEqual:HOUSE])
		{
			GraphInterfaceNode * deviceNode = [[GraphInterfaceNode alloc] initWithInterface:self];
		
			if (lastNode != nil)
			{
				GraphInterfaceMoveAction * moveNextAction = [[GraphInterfaceMoveAction alloc] init];
				[moveNextAction setDestinationNode:deviceNode];
				[lastNode setNextAction:moveNextAction];
				[moveNextAction release];
			
				GraphInterfaceMoveAction * movePreviousAction = [[GraphInterfaceMoveAction alloc] init];
				[movePreviousAction setDestinationNode:lastNode];
				[deviceNode setPreviousAction:movePreviousAction];
				[movePreviousAction release];
			
				[lastNode release];
			}

			lastNode = [deviceNode retain];

			if (firstNode == nil)
				firstNode = [deviceNode retain];

			// Say name of device.
			
			GraphInterfaceSpeechAction * speechAutoAction = [[GraphInterfaceSpeechAction alloc] init];
			[speechAutoAction setSpeech:[device valueForKey:SHION_NAME]];
			[deviceNode setAutoAction:speechAutoAction];
			[speechAutoAction release];
			
			// Go home.
			
			GraphInterfaceMoveAction * moveBackAction = [[GraphInterfaceMoveAction alloc] init];
			[moveBackAction setDestinationNode:homeNode];
			[deviceNode setCancelAction:moveBackAction];
			[moveBackAction release];

			// Go to commands. Come back on cancel.
			
			GraphInterfaceMoveAction * moveOkBackAction = [[GraphInterfaceMoveAction alloc] init];
			[moveOkBackAction setDestinationNode:deviceNode];
			
			GraphInterfaceNode * commandsNode = [self commandsNodeForDevice:device cancelAction:moveOkBackAction];
												 
			GraphInterfaceMoveAction * moveOkAction = [[GraphInterfaceMoveAction alloc] init];
			[moveOkAction setDestinationNode:commandsNode];
			[deviceNode setOkAction:moveOkAction];
			
			[commandsNode release];
			[moveOkBackAction release];
		}
	}

	/*
	
	 // TODO: implement
	 
	NSEnumerator * snapshotIter = [snapshots objectEnumerator];
	SnapshotDictionary * snapshot = nil;
	while (snapshot = [snapshotIter nextObject])
	{
		GraphInterfaceNode * snapNode = [[GraphInterfaceNode alloc] init];
		
		if (lastNode != nil)
		{
			GraphInterfaceMoveAction * moveNextAction = [[GraphInterfaceMoveAction alloc] init];
			[moveNextAction setDestinationNode:snapNode];
			[lastNode setNextAction:moveNextAction];
			[moveNextAction release];
			
			GraphInterfaceMoveAction * movePreviousAction = [[GraphInterfaceMoveAction alloc] init];
			[movePreviousAction setDestinationNode:lastNode];
			[snapNode setPreviousAction:movePreviousAction];
			[movePreviousAction release];
			
			[lastNode release];
		}
		
		lastNode = [snapNode retain];
		
		if (firstNode == nil)
			firstNode = [snapNode retain];
		
		GraphInterfaceMoveAction * moveBackAction = [[GraphInterfaceMoveAction alloc] init];
		[moveBackAction setDestinationNode:homeNode];
		[snapNode setCancelAction:moveBackAction];
		[moveBackAction release];
		
		// TODO make forward nodes to commands
		
		
		GraphInterfaceCompoundAction * compoundSayAction = [[GraphInterfaceCompoundAction alloc] init];
		
		GraphInterfaceSpeechAction * speechAutoAction = [[GraphInterfaceSpeechAction alloc] init];
		[speechAutoAction setSpeech:[device valueForKey:SHION_NAME]];
		[compoundSayAction addAction:speechAutoAction];
		[speechAutoAction release];
		
		// TODO: ENDLESS LOOP of AUTO ACTIONS?
		GraphInterfaceMoveAction * moveAutoAction = [[GraphInterfaceMoveAction alloc] init];
		[moveAutoAction setDestinationNode:deviceNode];
		[compoundSayAction addAction:moveAutoAction];
		[moveAutoAction release];
		
		[deviceNode setAutoAction:compoundSayAction];
	}

	if (firstNode != nil && lastNode != nil)
	{
		GraphInterfaceCompoundAction * compoundAction = [[GraphInterfaceCompoundAction alloc] init];
		
		GraphInterfaceSpeechAction * speechAutoAction = [[GraphInterfaceSpeechAction alloc] init];
		[speechAutoAction setSpeech:@"Please select a device or snapshot."];
		[compoundAction addAction:speechAutoAction];
		[speechAutoAction release];
		
		GraphInterfaceMoveAction * moveAutoAction = [[GraphInterfaceMoveAction alloc] init];
		[moveAutoAction setDestinationNode:firstNode];
		[compoundAction addAction:moveAutoAction];
		[moveAutoAction release];
		
		[homeNode setAutoAction:compoundAction];
		[compoundAction release];
		
		GraphInterfaceMoveAction * movePreviousAction = [[GraphInterfaceMoveAction alloc] init];
		[movePreviousAction setDestinationNode:lastNode];
		[firstNode setPreviousAction:movePreviousAction];
		[movePreviousAction release];

		GraphInterfaceMoveAction * moveNextAction = [[GraphInterfaceMoveAction alloc] init];
		[moveNextAction setDestinationNode:firstNode];
		[lastNode setNextAction:moveNextAction];
		[moveNextAction release];

		[firstNode release];
		[lastNode release];
	}
	 */
	
	GraphInterfaceMoveAction * wrapAction = [[GraphInterfaceMoveAction alloc] init];
	[wrapAction setDestinationNode:firstNode];
	[lastNode setNextAction:wrapAction];
	[wrapAction release];

	GraphInterfaceMoveAction * wrapBackAction = [[GraphInterfaceMoveAction alloc] init];
	[wrapBackAction setDestinationNode:lastNode];
	[firstNode setPreviousAction:wrapBackAction];
	[wrapBackAction release];
	
	if (firstNode != nil)
	{
		GraphInterfaceSpeechAction * helloAction = [[GraphInterfaceSpeechAction alloc] init];
		[helloAction setSpeech:@"Please select a device or snapshot."];
		[homeNode setAutoAction:helloAction];
		[helloAction release];
	

		GraphInterfaceMoveAction * moveAction = [[GraphInterfaceMoveAction alloc] init];
		[moveAction setDestinationNode:firstNode];

		[homeNode setOkAction:moveAction];
		[homeNode setNextAction:moveAction];
		[homeNode setPreviousAction:moveAction];
		
		[moveAction release];
	}
	else 
	{
		// TODO: no devices to control.
	}
	
	[self setHome:homeNode];
	[homeNode release];
}

- (void) reorganizeGraph;
{
	// Reorg. graph based upon invocation counts. Pref?
}

- (void) previousAction:(NSNotification *) theNote
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GRAPH_ACTION_PREVIOUS object:nil];
}

- (void) nextAction:(NSNotification *) theNote
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GRAPH_ACTION_NEXT object:nil];
}

- (void) okAction:(NSNotification *) theNote
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GRAPH_ACTION_OK object:nil];
}

- (void) cancelAction:(NSNotification *) theNote
{
	[[NSNotificationCenter defaultCenter] postNotificationName:GRAPH_ACTION_CANCEL object:nil];
}

@end
