/*
 *  Shion.c
 *  Shion
 *
 *  Created by Chris Karr on 8/19/09.
 *  Copyright 2009 CASIS LLC. All rights reserved.
 *
 */

#import "Shion.h"

SInt32 getVersion ()
{
	SInt32 MacVersion;
	
	if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr)
		return MacVersion;
	
	return 0;
}

