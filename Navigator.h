//
//  Navigator.h
//  ARDrone
//
//  Created by Chris Eidhof on 30.12.13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

@import CoreLocation;

@interface Navigator : NSObject

@property (nonatomic, strong) CLLocation *targetLocation;
@property (nonatomic, readonly) CLLocationDirection directionDifferenceToTarget;
@property (nonatomic, readonly) CLLocationDistance distanceToTarget;

@end
