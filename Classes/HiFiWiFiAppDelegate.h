//
//  HiFiWiFiAppDelegate.h
//  HiFiWiFi
//
//  Created by Aron Cedercrantz on 02/12/10.
//  Copyright 2010 Fruit Is Good. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HiFiWiFiViewController;

@interface HiFiWiFiAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    HiFiWiFiViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet HiFiWiFiViewController *viewController;

@end

