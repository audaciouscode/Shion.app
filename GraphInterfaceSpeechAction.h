//
//  GraphInterfaceSpeechAction.h
//  Shion
//
//  Created by Chris Karr on 9/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GraphInterfaceAction.h"

@interface GraphInterfaceSpeechAction : GraphInterfaceAction 
{
	NSString * speech;
}

- (void) setSpeech:(NSString *) newSpeech;

@end
