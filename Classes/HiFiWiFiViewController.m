//
//  HiFiWiFiViewController.m
//  HiFiWiFi
//
//  Created by Aron Cedercrantz on 02/12/10.
//  Copyright 2010 Fruit Is Good. All rights reserved.
//

#import "HiFiWiFiViewController.h"
#import "MBProgressHUD.h"


#pragma mark Constants
#define kFGAccelerometerFrequency			60.0 // Hz
#define kFGFilteringFactor					0.6
#define kFGAccelerationZTrigger				0.6

#define kFGFlipAnimationTime				1.0


#pragma mark -
#pragma mark 
#pragma mark HiFiWiFiViewController private API
@interface HiFiWiFiViewController ()

- (void)changeToView:(UIView *)aView animate:(BOOL)animate;
- (void)flipToView:(UIView *)aView;

- (void)configureAccelerometer;
- (void)suspendAccelerometer;
- (void)resumeAccelerometer;

- (void)establishConnectionWithOtherDevice;

@end


#pragma mark -
#pragma mark 
#pragma mark HiFiWiFiViewController implementation
@implementation HiFiWiFiViewController

#pragma mark Properties
@synthesize startView		= _startView;
@synthesize noFriendView	= _noFriendView;
@synthesize highFiveView	= _highFiveView;

@synthesize infoView		= _infoView;



#pragma mark Init
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		_activeView = nil;
        isLookingForFriend = NO;
    }
    return self;
}


#pragma mark Cleanup
- (void)dealloc
{
	_activeView = nil;
	
	[_startView release];
	[_noFriendView release];
	[_highFiveView release];
	
	[_infoView release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


#pragma mark View management
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait ||
			interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self changeToView:[self startView] animate:NO];
	[self configureAccelerometer];
}

- (void)changeToView:(UIView *)aView animate:(BOOL)animate
{
	if (aView != _activeView) {
		DLog(@"to");
		[_activeView removeFromSuperview];
		_activeView = aView;
		[[self view] addSubview:aView];
	}
}

- (void)flipToView:(UIView *)aView leftToRight:(BOOL)leftToRight
{
	if (aView != _activeView) {
		[UIView transitionWithView:[self view]
						  duration:kFGFlipAnimationTime
						   options:(leftToRight
									? UIViewAnimationOptionTransitionFlipFromLeft
									: UIViewAnimationOptionTransitionFlipFromRight)
						animations:^{
							[_activeView removeFromSuperview];
							_activeView = aView;
							[[self view] addSubview:aView];
						}
						completion:NULL];
	}
}


#pragma mark Info view actions
- (IBAction)showInfoView:(id)sender
{
	[self suspendAccelerometer];
	[self flipToView:[self infoView] leftToRight:YES];
}

- (IBAction)hideInfoView:(id)sender
{
	[self resumeAccelerometer];
	[self flipToView:[self startView] leftToRight:NO];
}


#pragma mark Device connectioning
- (void)establishConnectionWithOtherDevice
{
	sleep(3);
}


#pragma mark Acceleration management
- (void)configureAccelerometer
{
	UIAccelerometer *accelerometer = [UIAccelerometer sharedAccelerometer];
	[accelerometer setUpdateInterval:(1 / kFGAccelerometerFrequency)];
	[accelerometer setDelegate:self];
}

- (void)suspendAccelerometer
{
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];
}

- (void)resumeAccelerometer
{
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
}


#pragma mark UIAccelerometerDelegate method 
- (void)accelerometer:(UIAccelerometer *)accelerometer
		didAccelerate:(UIAcceleration *)acceleration
{
	if (!isLookingForFriend) {
		accelZ = [acceleration z] -
				 (([acceleration z] * kFGFilteringFactor) +
				  (accelZ * (1.0 - kFGFilteringFactor)));
	
		if (fabs(accelZ) > kFGAccelerationZTrigger) {
			DLog(@"%f", fabs(accelZ));
			
			[self suspendAccelerometer];
			isLookingForFriend = YES;
			
			// TODO: Toogle launching if high five stuff...
			MBProgressHUD *lookingForFriendsHUD = [[MBProgressHUD alloc] initWithView:[self view]];
			[lookingForFriendsHUD setLabelText:NSLocalizedString(@"High fiveing", @"Looking for friends HUD label")];
			[[self view] addSubview:lookingForFriendsHUD];
			[lookingForFriendsHUD setDelegate:self];
			[lookingForFriendsHUD showWhileExecuting:@selector(establishConnectionWithOtherDevice)
											onTarget:self
										  withObject:nil
											animated:YES];
		}
	}
}


#pragma mark MBProgressHUDDelegate method
- (void)hudWasHidden:(MBProgressHUD *)hud
{
	// TODO: IF no friend found show noFriendsView ELSE show highFiveView
	// Temp, this should be done either after a short delay when no friends
	// found or after all the high five animations, sound and stuff are done +
	// a short delay.
	isLookingForFriend = NO;
	[self resumeAccelerometer];
}

@end
#pragma mark -

