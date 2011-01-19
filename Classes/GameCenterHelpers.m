//
//  GameCenterHelpers.m
//  HiFiWiFi
//
//  Created by Aron Cedercrantz on 20/01/11.
//  Copyright 2011 Fruit Is Good. All rights reserved.
//

#import "GameCenterHelpers.h"


BOOL isGameCenterAvailable()
{
	// Check for presence of GKLocalPlayer API.
	Class gcClass = (NSClassFromString(@"GKLocalPlayer"));

	// The device must be running running iOS 4.1 or later.
	NSString *reqSysVer = @"4.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);

	return (gcClass && osVersionSupported);
}
