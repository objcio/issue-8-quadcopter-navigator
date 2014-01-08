//
//  DroneCommunicator.h
//  ARDrone
//
//  Created by Chris Eidhof on 29.12.13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DroneNavigationState;

@interface DroneCommunicator : NSObject

- (void)setupDefaults;

/// @a amount is clamped from -1 (backwards) to +1 (forward)
@property (nonatomic) double forwardSpeed;
/// @a amount is clamped from -1 (CCW) to +1 (CW)
@property (nonatomic) double rotationSpeed;

@property (nonatomic, strong, readonly) DroneNavigationState *navigationState;

@property (nonatomic) BOOL forceHover;

@end



@interface DroneCommunicator (Convenience)

- (void)resetEmergency;
- (void)takeoff;
- (void)land;
- (void)hover;

@end
