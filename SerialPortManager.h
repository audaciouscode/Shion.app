//
//  SerialPortManager.h
//  Shion
//
//  Created by Chris Karr on 1/2/09.
//  Copyright 2009 Audacious Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Shion/ASDeviceController.h>

#define PORTS @"ports"
#define MODELS @"models"

@interface SerialPortManager : NSObject 
{
	NSMutableDictionary * properties;
}

- (id) valueForKey:(NSString *) key;
- (void) setValue:(id) value forKey:(NSString *) key;

- (ASDeviceController *) getController;

- (void) save;

@end
