//
//  WiFiHiFiAppDelegate.h
//  WiFiHiFi
//
//  Created by Aron Cedercrantz on 02/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WiFiHiFiViewController;

@interface WiFiHiFiAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    WiFiHiFiViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet WiFiHiFiViewController *viewController;

@end

