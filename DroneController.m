//
// Created by chris on 06.01.14.
//

#import "DroneController.h"
#import "DroneCommunicator.h"
#import "Navigator.h"


@interface DroneController ()

@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) DroneCommunicator *communicator;
@property (nonatomic, strong) Navigator *navigator;

@end

@implementation DroneController

- (id)initWithCommunicator:(DroneCommunicator*)communicator navigator:(Navigator*)navigator
{
    self = [super init];
    if (self) {
        self.communicator = communicator;
        self.navigator = navigator;
    }

    return self;
}


- (void)start
{
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                        target:self
                                                      selector:@selector(updateTimerFired:)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)stop
{
    [self.updateTimer invalidate];
}

- (void)updateTimerFired:(NSTimer *)timer;
{
    [self.delegate droneController:self updateTimerFired:timer];

    switch (self.droneActivity) {
        case DroneActivityFlyToTarget:
            [self updateDroneCommands];
            break;
        case DroneActivityHover:
            [self.communicator hover];
            break;
        default:
            break;
    }
}

- (void)updateDroneCommands;
{
    if (self.navigator.distanceToTarget < 1) {
        self.droneActivity = DroneActivityHover;
    } else {
        static double const rotationSpeedScale = 0.01;
        self.communicator.rotationSpeed = self.navigator.directionDifferenceToTarget * rotationSpeedScale;
        BOOL roughlyInRightDirection = fabs(self.navigator.directionDifferenceToTarget) < 45.;
        self.communicator.forwardSpeed = roughlyInRightDirection ? 0.2 : 0;
    }
}

- (void)takeOff
{
    [self.communicator takeoff];
    [self.communicator hover];
    // This is not very pretty. But we just wait a few seconds before doing anything.
    double delayInSeconds = 4.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.communicator.forceHover = NO;
    });
}

@end
