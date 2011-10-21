//
//  ASPowerLincSerialRFController.h
//  Shion Framework
//
//  Created by Chris Karr on 10/20/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ASPowerLinc2412Controller.h"

@interface ASPowerLincSerialRFController : ASPowerLinc2412Controller
{

}

+ (ASPowerLincSerialRFController *) controllerWithPath:(NSString *) path;

@end
