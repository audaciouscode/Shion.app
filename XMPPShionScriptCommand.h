//
//  XMPPShionScriptCommand.h
//  Shion
//
//  Created by Chris Karr on 4/20/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPPIQCommand.h"

@interface XMPPShionScriptCommand : XMPPIQCommand 
{
	NSString * script;
}

- (void) setScript:(NSString *) queryScript;


@end
