//
//  GroupView.h
//  Shion
//
//  Created by Chris Karr on 4/12/10.
//  Copyright 2010 CASIS LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BlackView.h"

@interface GroupView : BlackView 
{
	NSMutableArray * deviceAreas;
	
	NSString * highlighted;
}

@end
