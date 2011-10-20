//
//  Lock.h
//  Shion
//
//  Created by Chris Karr on 7/6/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Device.h"

#define LOCK @"Lock"

@interface Lock : Device 
{

}

- (void) lock;
- (void) unlock;

- (BOOL) isLocked;

@end
