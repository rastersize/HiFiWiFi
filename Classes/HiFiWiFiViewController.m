//
//  HiFiWiFiViewController.m
//  HiFiWiFi
//
//  Created by Aron Cedercrantz on 02/12/10.
//  Copyright 2010 Fruit Is Good. All rights reserved.
//

#import "HiFiWiFiViewController.h"
#import "MBProgressHUD.h"
#import "GameCenterHelpers.h"

#import <GameKit/GameKit.h>


#pragma mark Constants
#define kFGAccelerometerFrequency			60.0 // Hz
#define kFGFilteringFactor					0.6
#define kFGAccelerationZTrigger				0.6

#define kFGFlipAnimationTime				1.0  // seconds
#define kFGChangeViewAnimationTime			200.0  // seconds

#define kFGTimeoutInterval					5.0  // seconds
#define kFGHighFiveDelay					2.0  // seconds
#define kFGReturnToStartDelay				40.0 // seconds

NSString *const kFGAppGKSessionID			= @"com.fruitisgood.HiFiWiFi";

NSString *const kFGBluetoothAvailabilityChangedNotification = @"BluetoothAvailabilityChangedNotification";



#pragma mark -
#pragma mark 
#pragma mark HiFiWiFiViewController private API
// TODO: Change signature to start with an underscore (_) since they are private
@interface HiFiWiFiViewController ()

- (void)changeToView:(UIView *)aView animate:(BOOL)animate;
- (void)flipToView:(UIView *)aView leftToRight:(BOOL)leftToRight;

- (void)showStartViewAnimated;
- (void)showNoFriendView;

- (void)hideLookingForFriendsHUD;

- (void)configureAccelerometer;
- (void)suspendAccelerometer;
- (void)resumeAccelerometer;

- (void)initHighFiveDelayTimer;
- (void)highFiveDelayTimerDone:(id)sender;

- (void)establishConnectionWithOtherDevice;
- (void)disconnectPeerSession;
- (void)peerSessionFailed:(id)sender;

- (void)_authenticateWithGameCenter;
- (void)_registerForAuthenticationNotification;
- (void)_authenticationChanged;
- (BOOL)_useGameCenter;

@end


#pragma mark -
#pragma mark 
#pragma mark HiFiWiFiViewController implementation
@implementation HiFiWiFiViewController

#pragma mark -
#pragma mark Properties
@synthesize startView		= _startView;
@synthesize noFriendView	= _noFriendView;
@synthesize highFiveView	= _highFiveView;

@synthesize infoView		= _infoView;


#pragma mark -
#pragma mark Init
- (void)awakeFromNib
{
	_activeView = nil;
	_isLookingForFriend = NO;
	_gameCenterAvailable = NO;
	
	_peerSession = [[GKSession alloc] initWithSessionID:kFGAppGKSessionID
											displayName:nil // nil == device name
											sessionMode:GKSessionModePeer];
	[_peerSession setDisconnectTimeout:kFGTimeoutInterval];
	[_peerSession setDelegate:self];
	// No why the h*ll would we do this? Well, there happens to be a bug in iOS
	// 4.0.1 and up which seem to cause the Bluethooth stuff to not init properly
	// on first activation. Thus we let it init properly here and then turns it
	// off imediately. Not pretty but it "works".
	// TODO: Remove when bug in iOS is fixed
	[_peerSession setAvailable:YES];
	[_peerSession setAvailable:NO];
}


#pragma mark Cleanup
- (void)dealloc
{	
	[[UIAccelerometer sharedAccelerometer] setDelegate:nil];
	
	[_peerSession setAvailable:NO];
	[_peerSession setDelegate:nil];
	[_peerSession release];
	
	[_lookingForFriendsHUD setDelegate:nil];
	[_lookingForFriendsHUD release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_activeView = nil;
	
	[_startView release];
	[_noFriendView release];
	[_highFiveView release];
	
	[_infoView release];
	
    [super dealloc];
}


#pragma mark -
#pragma mark View management
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait ||
			interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self changeToView:[self startView] animate:NO];

	if (isGameCenterAvailable()) {
		_gameCenterAvailable = YES;
		[self _authenticateWithGameCenter];
	}
	
	[self configureAccelerometer];
}

- (void)changeToView:(UIView *)aView animate:(BOOL)animate
{
	if (aView != _activeView) {
		if (animate) {
			[UIView transitionWithView:[self view]
							  duration:kFGChangeViewAnimationTime
							   options:UIViewAnimationOptionCurveEaseInOut
							animations:^{
								[_activeView removeFromSuperview];
								_activeView = aView;
								[[self view] addSubview:aView];
							}
							completion:^(BOOL comp){
								DLog(@"animation completed = %d", comp);
							}];
		} else {
			[_activeView removeFromSuperview];
			_activeView = aView;
			[[self view] addSubview:aView];
		}
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

- (void)showStartViewAnimated
{
	[self changeToView:[self startView] animate:YES];
}

- (void)showNoFriendView
{
	[self changeToView:[self noFriendView] animate:NO];
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(showStartViewAnimated)
											   object:nil];
	[self performSelector:@selector(showStartViewAnimated)
			   withObject:nil
			   afterDelay:kFGReturnToStartDelay];
}

- (void)hideLookingForFriendsHUD
{
	DLog(@"");
	[_lookingForFriendsHUD hide:NO];
}


#pragma mark MBProgressHUDDelegate method
- (void)hudWasHidden:(MBProgressHUD *)hud
{
	_lookingForFriendsHUD = nil;
}


#pragma mark UI actions
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


#pragma mark -
#pragma mark Session management
// TODO: Rename to connectPeerSession or something like that
- (void)establishConnectionWithOtherDevice
{
	if (!_isLookingForFriend) {
		_isLookingForFriend = YES;
		[_peerSession setAvailable:YES];
		[self performSelector:@selector(peerSessionFailed:)
				   withObject:self
				   afterDelay:kFGTimeoutInterval];
	}
}

- (void)disconnectPeerSession
{
	[_peerSession disconnectFromAllPeers];
	[_peerSession setAvailable:NO];
}

- (void)peerSessionFailed:(id)sender
{
	DLog(@"peer session timed out");
	
	[self hideLookingForFriendsHUD];
	[self disconnectPeerSession];
	[self showNoFriendView];
	[self initHighFiveDelayTimer];
	_isLookingForFriend = NO;
}


#pragma mark -
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

- (void)initHighFiveDelayTimer
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(highFiveDelayTimerDone:)
											   object:nil];
	[self performSelector:@selector(highFiveDelayTimerDone:)
			   withObject:nil
			   afterDelay:kFGHighFiveDelay];
}

- (void)highFiveDelayTimerDone:(id)sender
{
	DLog(@"");
	[self resumeAccelerometer];
}

#pragma mark UIAccelerometerDelegate method 
- (void)accelerometer:(UIAccelerometer *)accelerometer
		didAccelerate:(UIAcceleration *)acceleration
{
	if (!_isLookingForFriend) {
		// Apply a high-pass filter so we can discard "slow" movements.
		_accelZ = [acceleration z] -
				 (([acceleration z] * kFGFilteringFactor) +
				  (_accelZ * (1.0 - kFGFilteringFactor)));
	
		if (fabs(_accelZ) > kFGAccelerationZTrigger) {
			DLog(@"High Five occured with acceleration Y = %f", fabs(_accelZ));
			
			[self suspendAccelerometer];
			
			_lookingForFriendsHUD = [[MBProgressHUD alloc] initWithView:[self view]];
			[_lookingForFriendsHUD setLabelText:NSLocalizedString(@"High fiveing", @"Looking for friends HUD label")];
			[_lookingForFriendsHUD setDelegate:self];
			[_lookingForFriendsHUD setRemoveFromSuperViewOnHide:YES];
			[[self view] addSubview:_lookingForFriendsHUD];
			[_lookingForFriendsHUD show:YES];
			[self establishConnectionWithOtherDevice];
		}
	}
}


#pragma mark -
#pragma mark Game Center
- (void)_authenticateWithGameCenter
{
	[[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error){
		if (error != nil) {
			// TODO: Present error message
		}
	}];
}

- (void)_registerForAuthenticationNotification
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
		   selector:@selector(_authenticationChanged)
			   name:GKPlayerAuthenticationDidChangeNotificationName
			 object:nil];
}

- (void)_authenticationChanged
{
	if ([GKLocalPlayer localPlayer].isAuthenticated) {
		// Insert code here to handle a successful authentication.
	} else {
		// Insert code here to clean up any outstanding Game Center-related classes.
	}
}

- (BOOL)_useGameCenter
{
	return (_gameCenterAvailable && [[GKLocalPlayer localPlayer] isAuthenticated]);
}


#pragma mark GKSessionDelegate methods
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
	DLog(@"session: %@, peerID: %@, error: %@", session, peerID, error);
	
	// TODO: Present user with error message?
	[self peerSessionFailed:self];
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
	ALog(@"session: %@, error: %@", session, error);
	
	// TODO: Present user with error message?
	[self peerSessionFailed:self];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	DLog(@"session: %@, peerID: %@", session, peerID);

	if (![session acceptConnectionFromPeer:peerID error:NULL]) {
		DLog(@"failed to accept session: %@, peerID: %@", session, peerID);
		[self peerSessionFailed:self];
	} else {
		[self hideLookingForFriendsHUD];
		[self disconnectPeerSession];
		[self changeToView:[self highFiveView] animate:NO];
		[self initHighFiveDelayTimer];
		_isLookingForFriend = NO;
	}
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
	DLog(@"session: %@, peerID: %@, state: %@", session, peerID, state);
}


@end
#pragma mark -

