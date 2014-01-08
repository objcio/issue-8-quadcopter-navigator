//
//  ViewController.m
//  ARDrone
//
//  Created by Chris Eidhof on 29.12.13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "ViewController.h"
#import "DroneCommunicator.h"
#import "Navigator.h"
#import "DroneNavigationState.h"
#import "DroneController.h"
#import "RemoteClient.h"


@interface ViewController () <DroneControllerDelegate, RemoteClientDelegate>

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UILabel *otherLabel;
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, strong) DroneController *droneController;
@property (nonatomic, strong) Navigator *navigator;
@property (nonatomic, strong) RemoteClient *remoteClient;
@property (nonatomic, strong) DroneCommunicator *communicator;
@end



@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.communicator = [[DroneCommunicator alloc] init];
    [self.communicator setupDefaults];

    self.navigator = [[Navigator alloc] init];
    self.droneController = [[DroneController alloc] initWithCommunicator:self.communicator navigator:self.navigator];
    self.droneController.delegate = self;
    self.remoteClient = [[RemoteClient alloc] init];
    [self.remoteClient startBrowsing];
    self.remoteClient.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    [self.droneController start];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    [self.droneController stop];
}

- (void)updateDisplay
{
    self.otherLabel.text = [NSString stringWithFormat:@"%@°",
                            [NSNumberFormatter localizedStringFromNumber:@(self.navigator.directionDifferenceToTarget) numberStyle:NSNumberFormatterDecimalStyle]];
    self.label.text = [NSString stringWithFormat:@"%@ m",
                       [NSNumberFormatter localizedStringFromNumber:@(self.navigator.distanceToTarget) numberStyle:NSNumberFormatterDecimalStyle]];

    self.progressView.progress = self.communicator.navigationState.batteryLevel / 100.0f;
    self.textView.text = self.communicator.navigationState.description;
}

- (void)droneController:(DroneController *)controller updateTimerFired:(NSTimer *)fired
{
    [self updateDisplay];
}

- (IBAction)takeoff:(id)sender {
    [self.droneController takeOff];
}

- (IBAction)hover:(id)sender {
    [self.communicator hover];
}

- (IBAction)land:(id)sender {
    [self.communicator land];
}
- (IBAction)reset:(id)sender {
    [self.communicator resetEmergency];
}

- (IBAction)rotate:(id)sender
{
    self.communicator.forwardSpeed = 0;
    self.communicator.rotationSpeed = 1;
}

#pragma mark RemoteClient delegate

- (void)remoteClient:(RemoteClient *)client didReceiveTargetLocation:(CLLocation *)location
{
    self.droneController.droneActivity = DroneActivityFlyToTarget;
    self.navigator.targetLocation = location;
}

- (void)remoteClientDidReceiveResetCommand:(RemoteClient *)client
{
    [self reset:nil];
}

- (void)remoteClientDidReceiveTakeOffCommand:(RemoteClient *)client
{
    [self takeoff:nil];
}

- (void)remoteClientDidReceiveLandCommand:(RemoteClient *)client
{
    [self land:nil];
}

@end
