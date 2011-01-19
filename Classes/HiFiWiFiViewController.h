//
//  HiFiWiFiViewController.h
//  HiFiWiFi
//
//  Created by Aron Cedercrantz on 02/12/10.
//  Copyright 2010 Fruit Is Good. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

// TODO: Add multiple outcomes (perfect hit, good hit, lousy hit, miss) of high five


@interface HiFiWiFiViewController : UIViewController <MBProgressHUDDelegate, UIAccelerometerDelegate> {
	UIView					*_activeView;
	
	UIView					*_startView;
	UIView					*_noFriendView;
	UIView					*_highFiveView;

	UIView					*_infoView;

	UIAccelerationValue		accelZ;
	
	BOOL					isLookingForFriend;
}

@property (nonatomic, retain) IBOutlet UIView *startView;
@property (nonatomic, retain) IBOutlet UIView *noFriendView;
@property (nonatomic, retain) IBOutlet UIView *highFiveView;

@property (nonatomic, retain) IBOutlet UIView *infoView;


- (IBAction)showInfoView:(id)sender;
- (IBAction)hideInfoView:(id)sender;

@end

