//
//  HiFiWiFiViewController.m
//  HiFiWiFi
//
//  Created by Aron Cedercrantz on 02/12/10.
//  Copyright 2010 Fruit Is Good. All rights reserved.
//

#import "HiFiWiFiViewController.h"
#import "MBProgressHUD.h"

#import <GameKit/GameKit.h>


#pragma mark Constants
#define kFGAccelerometerFrequency			60.0 // Hz
#define kFGFilteringFactor					0.6
#define kFGAccelerationZTrigger				0.6

#define kFGFlipAnimationTime				1.0

#define kFGTimeoutInterval					5.0 // seconds


#pragma mark -
#pragma mark 
#pragma mark HiFiWiFiViewController private API
@interface HiFiWiFiViewController ()

- (void)changeToView:(UIView *)aView animate:(BOOL)animate;
- (void)flipToView:(UIView *)aView leftToRight:(BOOL)leftToRight;

- (void)configureAccelerometer;
- (void)suspendAccelerometer;
- (void)resumeAccelerometer;

- (void)establishConnectionWithOtherDevice;
- (void)disconnectPeerSession;
- (void)peerSessionTimedOut:(NSTimer *)theTimer;
- (void)cleanupTimeoutTimer;

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
        _isLookingForFriend = NO;
		
		_peerSession = [[GKSession alloc] initWithSessionID:nil // nil == app bundle id
												displayName:nil // nil == device name
												sessionMode:GKSessionModePeer];
		[_peerSession setDelegate:self];
    }
    return self;
}


#pragma mark Cleanup
- (void)dealloc
{
	[_timeoutTimer invalidate];
	_timeoutTimer = nil;
	
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	
	[_peerSession setDelegate:nil];
	[_peerSession release];
	
	[_lookingForFriendsHUD setDelegate:nil];
	[_lookingForFriendsHUD release];
	
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
	
	_lookingForFriendsHUD = [[MBProgressHUD alloc] initWithView:[self view]];
	[_lookingForFriendsHUD setLabelText:NSLocalizedString(@"High fiveing", @"Looking for friends HUD label")];
	[_lookingForFriendsHUD setDelegate:self];
	
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
	if (!_isLookingForFriend) {
		_timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kFGTimeoutInterval
														 target:self
													   selector:@selector(peerSessionTimedOut:)
													   userInfo:nil
														repeats:NO];
		[_peerSession setAvailable:YES];
	}

	while (_isLookingForFriend) { }
}

- (void)disconnectPeerSession
{
	[_peerSession disconnectFromAllPeers];
	[_peerSession setAvailable:NO];
}

- (void)peerSessionTimedOut:(NSTimer *)theTimer
{
	[self disconnectPeerSession];
	[self cleanupTimeoutTimer];
	_isLookingForFriend = NO;
}

- (void)cleanupTimeoutTimer
{
	[_timeoutTimer invalidate];
	_timeoutTimer = nil;
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
	if (!_isLookingForFriend) {
		// Apply a high-pass filter so we can discard "slow" movements.
		accelZ = [acceleration z] -
				 (([acceleration z] * kFGFilteringFactor) +
				  (accelZ * (1.0 - kFGFilteringFactor)));
	
		if (fabs(accelZ) > kFGAccelerationZTrigger) {
			DLog(@"%f", fabs(accelZ));
			
			[self suspendAccelerometer];
			_isLookingForFriend = YES;
			
			
			[[self view] addSubview:_lookingForFriendsHUD];
			[_lookingForFriendsHUD showWhileExecuting:@selector(establishConnectionWithOtherDevice)
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
}


#pragma mark GKSessionDelegate methods
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
	[self cleanupTimeoutTimer];
	DLog(@"session: %@, peerID: %@, error: %@", session, peerID, error);
	// TODO: Present error message
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
	[self cleanupTimeoutTimer];
	DLog(@"session: %@, error: %@", session, error);
	// TODO: Present error message
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	[self cleanupTimeoutTimer];
	
	DLog(@"session: %@, peerID: %@", session, peerID);

	if (![session acceptConnectionFromPeer:peerID error:NULL]) {
		// TODO: Present error message
	}
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
	[self cleanupTimeoutTimer];
	DLog(@"session: %@, peerID: %@, state: %@", session, peerID, state);
	
	// TODO: Show high five view, disconnect session and initiate the delay timer
}

@end
#pragma mark -

