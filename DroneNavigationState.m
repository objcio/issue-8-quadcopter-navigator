//
//  DroneNavigationState.m
//  ARDrone
//
//  Created by Daniel Eggert on 29/12/2013.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "DroneNavigationState.h"

/// These are defined in navdata_keys.h
typedef enum DroneNavigationTags_e : int32_t {
    NAVDATA_DEMO_TAG = 0,
    NAVDATA_TIME_TAG = 1,
    NAVDATA_RAW_MEASURES_TAG = 2,
    NAVDATA_PHYS_MEASURES_TAG = 3,
    NAVDATA_GYROS_OFFSETS_TAG = 4,
    NAVDATA_EULER_ANGLES_TAG = 5,
    NAVDATA_REFERENCES_TAG = 6,
    NAVDATA_TRIMS_TAG = 7,
    NAVDATA_RC_REFERENCES_TAG = 8,
    NAVDATA_PWM_TAG = 9,
    NAVDATA_ALTITUDE_TAG = 10,
    NAVDATA_VISION_RAW_TAG = 11,
    NAVDATA_VISION_OF_TAG = 12,
    NAVDATA_VISION_TAG = 13,
    NAVDATA_VISION_PERF_TAG = 14,
    NAVDATA_TRACKERS_SEND_TAG = 15,
    NAVDATA_VISION_DETECT_TAG = 16,
    NAVDATA_WATCHDOG_TAG = 17,
    NAVDATA_ADC_DATA_FRAME_TAG = 18,
    NAVDATA_VIDEO_STREAM_TAG = 19,
    NAVDATA_GAMES_TAG = 20,
    NAVDATA_PRESSURE_RAW_TAG = 21,
    NAVDATA_MAGNETO_TAG = 22,
    NAVDATA_WIND_TAG = 23,
    NAVDATA_KALMAN_PRESSURE_TAG = 24,
    NAVDATA_HDVIDEO_STREAM_TAG = 25,
    NAVDATA_WIFI_TAG = 26,
    NAVDATA_CKS_TAG = 0xFFFF,
} DroneNavigationTags;

// C.f. <https://projects.ardrone.org/embedded/ardrone-api/d6/dfd/struct__navdata__demo__t.html>
// With @c tag and @c size stripped
typedef struct __attribute__((packed)) {
    uint32_t controlState;
    uint32_t batteryLevel;
    float pitch;
    float roll;
    float yaw;
    uint32_t altitude;
    float speedX;
    float speedY;
    float speedZ;
} DroneNavigationReadouts;

uint32_t const WiFiLinkQualityUnknown = 0xffff;


@interface DroneNavigationState ()

@property (nonatomic) uint32_t state;
@property (nonatomic) uint32_t sequenceNumber;
@property (nonatomic) DroneNavigationReadouts readouts;
@property (nonatomic) BOOL hasReadouts;

@end


@implementation DroneNavigationState

- (id)init
{
    self = [super init];
    if (self) {
        _WiFiLinkQuality = WiFiLinkQualityUnknown;
    }
    return self;
}

+ (instancetype)stateFromNavigationData:(NSData *)data;
{
    DroneNavigationState *state = [[self alloc] init];
    if (! [state parseData:data]) {
        return nil;
    }
    return state;
}

- (BOOL)parseData:(NSData *)data;
{
    if ([data length] < sizeof(int32_t)) {
        NSLog(@"Invalid navigation data (too short). Ignoring.");
        return NO;
    }
    NSUInteger loc = 0;
    
    uint32_t header = 0;
    static uint32_t const magicHeaderValue = 0x55667788;
    [data getBytes:&header range:NSMakeRange(loc, sizeof(header))];
    loc += sizeof(header);
    header = NSSwapLittleIntToHost(header);
    if (header != magicHeaderValue) {
        NSLog(@"Invalid navigation data (header value doesn't match). Ignoring.");
        return NO;
    }
    
    uint32_t state = 0;
    [data getBytes:&state range:NSMakeRange(loc, sizeof(state))];
    loc += sizeof(state);
    state = NSSwapLittleIntToHost(state);
    self.state = state;
    
    uint32_t sequence = 0;
    [data getBytes:&sequence range:NSMakeRange(loc, sizeof(sequence))];
    loc += sizeof(sequence);
    sequence = NSSwapLittleIntToHost(sequence);
    self.sequenceNumber = sequence;
    
    // Skip 'vision tag'
    loc += 4;
    
    while (loc + (2 * sizeof(uint16_t)) <= [data length]) {
        uint16_t option_tag = 0;
        uint16_t option_length = 0;
        [data getBytes:&option_tag range:NSMakeRange(loc, sizeof(option_tag))];
        loc += sizeof(option_tag);
        option_tag = NSSwapLittleShortToHost(option_tag);
        [data getBytes:&option_length range:NSMakeRange(loc, sizeof(option_length))];
        loc += sizeof(option_length);
        option_length = NSSwapLittleShortToHost(option_length);
        
        // The data structures found inside these are defined inside navdata_common.h
        
        DroneNavigationTags tag = option_tag;
        switch (tag) {
            case NAVDATA_DEMO_TAG: {
                DroneNavigationReadouts readouts = {};
                if (sizeof(readouts) <= option_length) {
                    [data getBytes:&readouts range:NSMakeRange(loc, sizeof(readouts))];
                    // TODO: swap little to host
                    self.readouts = readouts;
                    self.hasReadouts = YES;
                }
                break;
            }
            case NAVDATA_WIFI_TAG: {
                uint32_t linkQuality = 0;
                [data getBytes:&linkQuality range:NSMakeRange(loc, sizeof(linkQuality))];
                _WiFiLinkQuality = linkQuality;
                break;
            }
            default:
                break;
        }
        loc += option_length - 4;
    }

    
    return YES;
}

- (NSString *)description;
{
    NSMutableString *description = [NSMutableString string];
    
    [description appendFormat:@"%x ", self.sequenceNumber];
    
    switch (self.controlState) {
        case DroneControlStateDefault:
            [description appendString:@"state = Default"];
            break;
        case DroneControlStateInit:
            [description appendString:@"state = Init"];
            break;
        case DroneControlStateLanded:
            [description appendString:@"state = Landed"];
            break;
        case DroneControlStateFlying:
            [description appendString:@"state = Flying"];
            break;
        case DroneControlStateHovering:
            [description appendString:@"state = Hovering"];
            break;
        case DroneControlStateTest:
            [description appendString:@"state = Test"];
            break;
        case DroneControlStateTakeoff:
            [description appendString:@"state = Takeoff"];
            break;
        case DroneControlStateGotoFix:
            [description appendString:@"state = GotoFix"];
            break;
        case DroneControlStateLanding:
            [description appendString:@"state = Landing"];
            break;
        case DroneControlStateInvalid:
        default:
            break;
    }
    
    NSMutableArray *flags = [NSMutableArray array];
    if (self.flying) {
        [flags addObject:@"flying"];
    }
    if (self.videoEnabled) {
        [flags addObject:@"videoEnabled"];
    }
    if (self.visionEnabled) {
        [flags addObject:@"visionEnabled"];
    }
    if (self.altitudeControlActive) {
        [flags addObject:@"altitudeControlActive"];
    }
    if (self.userFeedbackOn) {
        [flags addObject:@"userFeedbackOn"];
    }
    if (self.controlReceived) {
        [flags addObject:@"controlReceived"];
    }
    if (self.trimReceived) {
        [flags addObject:@"trimReceived"];
    }
    if (self.trimRunning) {
        [flags addObject:@"trimRunning"];
    }
    if (self.trimSucceeded) {
        [flags addObject:@"trimSucceeded"];
    }
    if (self.navDataDemoOnly) {
        [flags addObject:@"navDataDemoOnly"];
    }
    if (self.navDataBootstrap) {
        [flags addObject:@"navDataBootstrap"];
    }
    if (self.motorsDown) {
        [flags addObject:@"motorsDown"];
    }
    if (self.gyrometersDown) {
        [flags addObject:@"gyrometersDown"];
    }
    if (self.batteryTooLow) {
        [flags addObject:@"batteryTooLow"];
    }
    if (self.batteryTooHigh) {
        [flags addObject:@"batteryTooHigh"];
    }
    if (self.timerElapsed) {
        [flags addObject:@"timerElapsed"];
    }
    if (self.notEnoughPower) {
        [flags addObject:@"notEnoughPower"];
    }
    if (self.angelsOutOufRange) {
        [flags addObject:@"angelsOutOufRange"];
    }
    if (self.tooMuchWind) {
        [flags addObject:@"tooMuchWind"];
    }
    if (self.ultrasonicSensorDeaf) {
        [flags addObject:@"ultrasonicSensorDeaf"];
    }
    if (self.cutoutSystemDetected) {
        [flags addObject:@"cutoutSystemDetected"];
    }
    if (self.PICVersionNumberOK) {
        [flags addObject:@"PICVersionNumberOK"];
    }
    if (self.ATCodedThreadOn) {
        [flags addObject:@"ATCodedThreadOn"];
    }
    if (self.navDataThreadOn) {
        [flags addObject:@"navDataThreadOn"];
    }
    if (self.videoThreadOn) {
        [flags addObject:@"videoThreadOn"];
    }
    if (self.acquisitionThreadOn) {
        [flags addObject:@"acquisitionThreadOn"];
    }
    if (self.controlWatchdogDelayed) {
        [flags addObject:@"controlWatchdogDelayed"];
    }
    if (self.ADCWatchdogDelayed) {
        [flags addObject:@"ADCWatchdogDelayed"];
    }
    if (self.communicationProblemOccurred) {
        [flags addObject:@"communicationProblemOccurred"];
    }
    if (self.emergency) {
        [flags addObject:@"emergency"];
    }
    [description appendFormat:@", flags = [%@]", [flags componentsJoinedByString:@", "]];
    
    if (self.controlAlgorithm == EulerAnglesControlAlgorithm) {
        [description appendString:@", control = EulerAngles"];
    } else if (self.controlAlgorithm == AugularSpeedControlAlgorithm) {
        [description appendString:@", control = AugularSpeed"];
    }
    
    if (self.WiFiLinkQuality != WiFiLinkQualityUnknown) {
        [description appendFormat:@"WiFi Link: %u", self.WiFiLinkQuality];
    }
    
    if (self.hasReadouts) {
        [description appendFormat:@", battery = %u", self.batteryLevel];
        
        [description appendFormat:@", pitch = %g", self.pitch];
        [description appendFormat:@", roll = %g", self.roll];
        [description appendFormat:@", yaw = %g", self.yaw];
        [description appendFormat:@", altitude = %g", self.altitude];
        [description appendFormat:@", speed = %g / %g / %g", self.speedX, self.speedY, self.speedZ];
    }
    
    return description;
}

- (BOOL)flying;
{
    return (self.state & 1) != 0;
}
- (BOOL)videoEnabled;
{
    return (self.state & (1 << 1)) != 0;
}
- (BOOL)visionEnabled;
{
    return (self.state & (1 << 2)) != 0;
}
- (DroneControlAlgorithm)controlAlgorithm;
{
    return (self.state & (1 << 3)) != 0 ? AugularSpeedControlAlgorithm : EulerAnglesControlAlgorithm;
}
- (BOOL)altitudeControlActive;
{
    return (self.state & (1 << 4)) != 0;
}
- (BOOL)userFeedbackOn;
{
    return (self.state & (1 << 5)) != 0;
}
- (BOOL)controlReceived;
{
    return (self.state & (1 << 6)) != 0;
}
- (BOOL)trimReceived;
{
    return (self.state & (1 << 7)) != 0;
}
- (BOOL)trimRunning;
{
    return (self.state & (1 << 8)) != 0;
}
- (BOOL)trimSucceeded;
{
    return (self.state & (1 << 9)) != 0;
}
- (BOOL)navDataDemoOnly;
{
    return (self.state & (1 << 10)) != 0;
}
- (BOOL)navDataBootstrap;
{
    return (self.state & (1 << 11)) != 0;
}
- (BOOL)motorsDown;
{
    return (self.state & (1 << 12)) != 0;
}
- (BOOL)gyrometersDown;
{
    return (self.state & (1 << 14)) != 0;
}
- (BOOL)batteryTooLow;
{
    return (self.state & (1 << 15)) != 0;
}
- (BOOL)batteryTooHigh;
{
    return (self.state & (1 << 16)) != 0;
}
- (BOOL)timerElapsed;
{
    return (self.state & (1 << 17)) != 0;
}
- (BOOL)notEnoughPower;
{
    return (self.state & (1 << 18)) != 0;
}
- (BOOL)angelsOutOufRange;
{
    return (self.state & (1 << 19)) != 0;
}
- (BOOL)tooMuchWind;
{
    return (self.state & (1 << 20)) != 0;
}
- (BOOL)ultrasonicSensorDeaf;
{
    return (self.state & (1 << 21)) != 0;
}
- (BOOL)cutoutSystemDetected;
{
    return (self.state & (1 << 22)) != 0;
}
- (BOOL)PICVersionNumberOK;
{
    return (self.state & (1 << 23)) != 0;
}
- (BOOL)ATCodedThreadOn;
{
    return (self.state & (1 << 24)) != 0;
}
- (BOOL)navDataThreadOn;
{
    return (self.state & (1 << 25)) != 0;
}
- (BOOL)videoThreadOn;
{
    return (self.state & (1 << 26)) != 0;
}
- (BOOL)acquisitionThreadOn;
{
    return (self.state & (1 << 27)) != 0;
}
- (BOOL)controlWatchdogDelayed;
{
    return (self.state & (1 << 28)) != 0;
}
- (BOOL)ADCWatchdogDelayed;
{
    return (self.state & (1 << 29)) != 0;
}
- (BOOL)communicationProblemOccurred;
{
    return (self.state & (1 << 30)) != 0;
}
- (BOOL)emergency;
{
    return (self.state & (1 << 31)) != 0;
}

- (DroneControlState)controlState
{
    if (! self.hasReadouts) {
        return DroneControlStateInvalid;
    }
    return (DroneControlState) ((self.readouts.controlState >> 16) + 1);
}
- (uint32_t)batteryLevel;
{
    return self.readouts.batteryLevel;
}
- (double)pitch;
{
    return self.readouts.pitch * 0.001;
}
- (double)roll;
{
    return self.readouts.roll * 0.001;
}
- (double)yaw;
{
    return self.readouts.yaw * 0.001;
}
- (double)altitude;
{
    return self.readouts.altitude * 0.001;
}
- (double)speedX;
{
    return self.readouts.speedX;
}
- (double)speedY;
{
    return self.readouts.speedY;
}
- (double)speedZ;
{
    return self.readouts.speedZ;
}

@end
