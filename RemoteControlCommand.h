//
//  RemoteControlCommand.h
//  ARDrone
//
//  Created by Daniel Eggert on 30/12/2013.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

@import CoreLocation;




@interface RemoteControlCommand : NSObject <NSSecureCoding>

+ (instancetype)commandFromNetworkData:(NSData *)data;
- (NSData *)encodeAsNetworkData;

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) BOOL stop;

@end
