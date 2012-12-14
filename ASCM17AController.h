//
//  ASCM17AController.h
//  Shion Framework
//
//  Created by Chris Karr on 10/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ASDeviceController.h"

@interface ASCM17AController : ASDeviceController 
{
	NSTimer * wakeup;
	NSFileHandle * handle;
}

+ (ASCM17AController *) controllerWithPath:(NSString *) path;

@end
