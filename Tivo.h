//
//  Tivo.h
//  Shion
//
//  Created by Chris Karr on 4/11/11.
//  Copyright 2011 Audacious Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Device.h"

#define TIVO_DVR @"TiVo Digital Video Recorder"

@interface Tivo : Device 
{
	BOOL fetching;
	NSLock * lock;
}

- (NSArray *) recordings;

@end
