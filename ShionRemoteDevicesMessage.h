//
//  ShionRemoteDevicesMessage.h
//  Shion
//
//  Created by Chris Karr on 10/14/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMPPIQCommand.h"

@interface ShionRemoteDevicesMessage : XMPPIQCommand 
{

}

+ (NSXMLElement *) elementForDevice:(NSDictionary *) device;

@end
