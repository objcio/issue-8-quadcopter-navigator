//
//  DroneNavigationState.h
//  ARDrone
//
//  Created by Daniel Eggert on 29/12/2013.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum DroneControlAlgorithm_e : int8_t {
    DroneControlAlgorithmInvalid = 0,
    EulerAnglesControlAlgorithm,
    AugularSpeedControlAlgorithm,
} DroneControlAlgorithm;

typedef enum DroneControlState_e : int8_t {
    DroneControlStateInvalid = 0,
    DroneControlStateDefault,
    DroneControlStateInit,
    DroneControlStateLanded,
    DroneControlStateFlying,
    DroneControlStateHovering,
    DroneControlStateTest,
    DroneControlStateTakeoff,
    DroneControlStateGotoFix,
    DroneControlStateLanding,
} DroneControlState;

@interface DroneNavigationState : NSObject

+ (instancetype)stateFromNavigationData:(NSData *)data;

@property (readonly, nonatomic) uint32_t sequenceNumber;

@property (readonly, nonatomic) BOOL flying;
@property (readonly, nonatomic) BOOL videoEnabled;
@property (readonly, nonatomic) BOOL visionEnabled;
@property (readonly, nonatomic) DroneControlAlgorithm controlAlgorithm;
@property (readonly, nonatomic) BOOL altitudeControlActive;
@property (readonly, nonatomic) BOOL userFeedbackOn;
@property (readonly, nonatomic) BOOL controlReceived;
@property (readonly, nonatomic) BOOL trimReceived;
@property (readonly, nonatomic) BOOL trimRunning;
@property (readonly, nonatomic) BOOL trimSucceeded;
@property (readonly, nonatomic) BOOL navDataDemoOnly;
@property (readonly, nonatomic) BOOL navDataBootstrap;
@property (readonly, nonatomic) BOOL motorsDown;
@property (readonly, nonatomic) BOOL gyrometersDown;
@property (readonly, nonatomic) BOOL batteryTooLow;
@property (readonly, nonatomic) BOOL batteryTooHigh;
@property (readonly, nonatomic) BOOL timerElapsed;
@property (readonly, nonatomic) BOOL notEnoughPower;
@property (readonly, nonatomic) BOOL angelsOutOufRange;
@property (readonly, nonatomic) BOOL tooMuchWind;
@property (readonly, nonatomic) BOOL ultrasonicSensorDeaf;
@property (readonly, nonatomic) BOOL cutoutSystemDetected;
@property (readonly, nonatomic) BOOL PICVersionNumberOK;
@property (readonly, nonatomic) BOOL ATCodedThreadOn;
@property (readonly, nonatomic) BOOL navDataThreadOn;
@property (readonly, nonatomic) BOOL videoThreadOn;
@property (readonly, nonatomic) BOOL acquisitionThreadOn;
@property (readonly, nonatomic) BOOL controlWatchdogDelayed;
@property (readonly, nonatomic) BOOL ADCWatchdogDelayed;
@property (readonly, nonatomic) BOOL communicationProblemOccurred;
@property (readonly, nonatomic) BOOL emergency;

@property (readonly, nonatomic) DroneControlState controlState;
@property (readonly, nonatomic) uint32_t batteryLevel;
@property (readonly, nonatomic) double pitch;
@property (readonly, nonatomic) double roll;
@property (readonly, nonatomic) double yaw;
@property (readonly, nonatomic) double altitude;
@property (readonly, nonatomic) double speedX;
@property (readonly, nonatomic) double speedY;
@property (readonly, nonatomic) double speedZ;

@property (readonly, nonatomic) uint32_t WiFiLinkQuality;
extern uint32_t const WiFiLinkQualityUnknown;

@end
