//
// Created by chris on 06.01.14.
//

#import <Foundation/Foundation.h>

@class DroneController;

typedef enum DroneActivity_e {
    DroneActivityNone,
    DroneActivityFlyToTarget,
    DroneActivityHover,
} DroneActivity;

@class DroneController;
@class DroneCommunicator;
@class Navigator;

@protocol DroneControllerDelegate <NSObject>

- (void)droneController:(DroneController *)controller updateTimerFired:(NSTimer *)fired;
@end

@interface DroneController : NSObject

@property (nonatomic) DroneActivity droneActivity;
@property (nonatomic,weak) id<DroneControllerDelegate> delegate;

- (id)initWithCommunicator:(DroneCommunicator *)communicator navigator:(Navigator *)navigator;
- (void)start;
- (void)stop;

- (void)takeOff;
- (void)land;
@end
