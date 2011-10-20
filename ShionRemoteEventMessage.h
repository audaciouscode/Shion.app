//
//  ShionRemoteEventMessage.h
//  Shion
//
//  Created by Chris Karr on 10/15/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPPIQCommand.h"

@interface ShionRemoteEventMessage : XMPPIQCommand 
{
	NSDictionary * eventDict;
}

- (id) initWithFrom:(NSString *) from to:(NSString *) to type:(NSString *) type id:(NSString *) identifier query:(NSString *) query eventDictionary:(NSDictionary *) dict;

@end
