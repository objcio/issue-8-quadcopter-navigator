//
//  DroneCommunicator.m
//  ARDrone
//
//  Created by Chris Eidhof on 29.12.13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "DroneCommunicator.h"

#import "DatagramSocket.h"
#import "DroneNavigationState.h"



enum ports_e : int {
    NavigationDataPort = 5554,
    OnBoardVideoPort = 5555,
    ATCommandPort = 5556,
};

static NSString * const DroneAddress = @"192.168.1.1";

static int const baseRefCommand = 0x11540000;

@interface DroneCommunicator () <DatagramSocketReceiveDelegate>

@property (nonatomic, strong) DatagramSocket *commandSocket;
@property (nonatomic, strong) DatagramSocket *navigationDataSocket;
@property (nonatomic) int commandSequence;
@property (nonatomic, strong) NSArray *flightState;
@property (readonly, nonatomic, copy) NSData *triggerData;
@property (nonatomic) BOOL isFlying;
@property (nonatomic, strong) NSTimer *updateTimer;


@property (nonatomic, strong) DroneNavigationState *navigationState;
- (void)sendString:(NSString *)string;
- (int)setConfigurationKey:(NSString *)key toString:(NSString *)string;
- (int)sendCommand:(NSString *)command arguments:(NSArray *)arguments;
- (void)sendCommandWithoutSequenceNumber:(NSString *)command arguments:(NSArray *)arguments;
- (NSArray *)convertedFlightState;
@end



@implementation DroneCommunicator

- (id)init
{
    self = [super init];
    if (self) {
        [self setupSockets];
        self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update:) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc
{
    [self.updateTimer invalidate];
    [self closeSockets];
}

- (void)setupSockets
{
    NSError *error = nil;
    self.commandSocket = [DatagramSocket ipv4socketWithAddress:DroneAddress port:ATCommandPort receiveDelegate:self receiveQueue:[NSOperationQueue mainQueue] error:&error];
    
    self.navigationDataSocket = [DatagramSocket ipv4socketWithAddress:DroneAddress port:NavigationDataPort receiveDelegate:self receiveQueue:[NSOperationQueue mainQueue] error:&error];
    // Sending the 'trigger' will cause the navigation data to start to be sent:
    [self.navigationDataSocket asynchronouslySendData:self.triggerData];
    
    NSAssert(self.commandSocket != nil, @"Failed to create command socket: %@", error);
}

- (NSData *)triggerData
{
    static char const trigger[4] = {0x01, 0x00, 0x00, 0x00};
    return [NSData dataWithBytes:trigger length:sizeof(trigger)];
}

- (void)closeSockets
{
    self.commandSocket = nil;
    self.navigationDataSocket = nil;
}

- (void)datagramSocket:(DatagramSocket *)datagramSocket didReceiveData:(NSData *)data;
{
    if (datagramSocket == self.navigationDataSocket) {
        [self didReceiveNavigationData:data];
    } else if (datagramSocket == self.commandSocket) {
        [self didReceiveCommandResponseData:data];
    }
}

- (void)didReceiveNavigationData:(NSData *)data;
{
    DroneNavigationState *state = [DroneNavigationState stateFromNavigationData:data];
    if (state != nil) {
        self.navigationState = state;
    }
}

- (void)didReceiveCommandResponseData:(NSData *)data;
{
    NSLog(@"Command response: %@", data);
}

- (void)sendString:(NSString*)string
{
    NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
    if (data != nil) {
        [self.commandSocket asynchronouslySendData:data];
        NSLog(@"sending %@", [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]);
    } else {
        NSLog(@"Unable to convert string to ASCII: %@", string);
    }
}

- (int)setConfigurationKey:(NSString *)key toString:(NSString *)string;
{
    NSString *command = [NSString stringWithFormat:@"CONFIG"];
    NSArray *arguments = @[[NSString stringWithFormat:@"\"%@\"", key],
                           [NSString stringWithFormat:@"\"%@\"", string]];
    return [self sendCommand:command arguments:arguments];
}

- (int)sendCommand:(NSString *)command arguments:(NSArray *)arguments;
{
    NSMutableArray *args2 = [NSMutableArray arrayWithArray:arguments];
    self.commandSequence++;
    NSString *seq = [NSString stringWithFormat:@"%d", self.commandSequence];
    [args2 insertObject:seq atIndex:0];
    [self sendCommandWithoutSequenceNumber:command arguments:args2];
    return self.commandSequence;
}

- (void)sendCommandWithoutSequenceNumber:(NSString *)command arguments:(NSArray *)arguments;
{
    NSMutableString *atString = [NSMutableString stringWithString:@"AT*"];
    [atString appendString:command];
    NSArray* processedArgs = [arguments valueForKey:@"description"];
    if (0 < arguments.count) {
        [atString appendString:@"="];
        [atString appendString:[processedArgs componentsJoinedByString:@","]];
    }
    [atString appendString:@"\r"];
    [self sendString:atString];
}

- (void)sendRefCommand:(uint32_t)command;
{
    [self sendCommand:@"REF" arguments:@[@(command)]];
}

- (void)sendPCommand:(NSArray*)arguments;
{
    [self sendCommand:@"PCMD" arguments:arguments];
}

- (void)resetEmergency
{
    self.isFlying = NO;
    [self sendRefCommand:baseRefCommand|(1<<8)];
}

- (void)update:(NSTimer *)timer;
{
    if (self.isFlying) {
        BOOL shouldMove = !self.forceHover && (self.rotationSpeed != 0 || self.forwardSpeed != 0);

        NSLog(@"force hover: %d, rotation speed: %f, forward speed: %f", self.forceHover, self.rotationSpeed, self.forwardSpeed);
        if (shouldMove) {
            self.flightState = @[@1,@0,@(self.forwardSpeed),@0,@(self.rotationSpeed)];
        } else {
            self.flightState = @[@0,@0,@0,@0,@0];
        }

        [self sendPCommand:self.convertedFlightState];
    }
}

- (NSArray *)convertedFlightState
{
    NSMutableArray *result = [NSMutableArray array];
    [result addObject:self.flightState[0]];

    for(int i = 1; i < self.flightState.count; i++){
        NSNumber *number = (id) self.flightState[i];
        union {
            float f;
            int i;
        } u;
        u.f = number.floatValue;
        [result addObject:@(u.i)];
    }
    return result;
}

- (void)setRotationSpeed:(double)rotationSpeed
{
    _rotationSpeed = fmax(-1, fmin(1, rotationSpeed));
}

- (void)setForwardSpeed:(double)forwardSpeed
{
    _forwardSpeed = fmax(-1, fmin(1, forwardSpeed));
}

- (void)setupDefaults
{
    [self setConfigurationKey:@"general:navdata_demo" toString:@"FALSE"];
    [self setConfigurationKey:@"control:altitude_max" toString:@"1600"];
    [self setConfigurationKey:@"control:flying_mode" toString:@"1000"];

    [self sendCommand:@"COMWDG" arguments:nil]; // WatchDog timer
    [self sendCommand:@"FTRIM" arguments:nil]; // Reset sensor
}
@end



@implementation DroneCommunicator (Convenience)

- (void)takeoff;
{
    self.isFlying = YES;
    self.forceHover = YES;
    [self sendRefCommand:baseRefCommand | (1<<9)];
}

- (void)land;
{
    self.isFlying = NO;
    [self sendRefCommand:baseRefCommand];
}

- (void)hover;
{
    self.forwardSpeed = 0;
    self.rotationSpeed = 0;
    self.forceHover = YES;
}

@end
