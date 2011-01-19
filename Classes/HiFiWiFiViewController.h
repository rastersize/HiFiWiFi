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
// TODO: Add GameCenter rankings (most high fives, most high altitude high fives, most low altitude high fives, most high speed high fives, highest speed high five, highest altitude high five, lowest altitude high five).
// TODO: Add GameCenter achivements (high altitude high five, low altitude high five, "fast five" (a high five done at greater than normal movement speed), "inaneley fast high five" (omg it's done so fast I can't believe the iPhone is still working), first high five, rookie high fiver (10), ..., ultimate high fiver (10000), moar).


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

