//
//  Navigator.m
//  ARDrone
//
//  Created by Chris Eidhof on 30.12.13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "Navigator.h"

#import "CLLocation+ObjcioHelpers.h"



@interface Navigator ()

@property (readonly, nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLHeading *lastKnownSelfHeading;
@property (nonatomic, strong) OBJDirection *direction;

@property (nonatomic, strong) CLLocation * lastKnowLocation;
@end



@interface Navigator (LocationManagerDelegate) <CLLocationManagerDelegate>
@end



@implementation Navigator

- (id)init
{
    self = [super init];
    if (self) {
        [self startCoreLocation];
    }
    return self;
}

- (void)startCoreLocation
{
    _locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [self.locationManager startUpdatingLocation];
    
    self.targetLocation = [[CLLocation alloc] initWithCoordinate:(CLLocationCoordinate2D){52.50532722, 13.41468919} altitude:10 horizontalAccuracy:0 verticalAccuracy:0 timestamp:nil];
    
    [self.locationManager startUpdatingHeading];
}

+ (NSSet *)keyPathsForValuesAffectingDistanceToTarget
{
    return [NSSet setWithObject:@"direction"];
}

- (CLLocationDistance)distanceToTarget;
{
    return self.direction.distance;
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager
{
    return YES;
}

+ (NSSet*)keyPathsForValuesAffectingDirection;
{
    return [NSSet setWithObjects:@"lastKnownLocation", @"targetLocation", nil];
}

- (OBJDirection *)direction
{
    return [self.lastKnowLocation directionToLocation:self.targetLocation];
}


+ (NSSet *)keyPathsForValuesAffectingDirectionDifferenceToTarget;
{
    return [NSSet setWithObjects:@"lastKnownSelfHeading", @"direction", nil];
}

- (CLLocationDirection)directionDifferenceToTarget;
{
    CLLocationDirection result = (self.direction.heading - self.lastKnownSelfHeading.trueHeading - 90);
    // Make sure the result is in the range -180 -> 180
    result = fmod(result + 180. + 360., 360.) - 180.;
    return result;
}

@end



@implementation Navigator (LocationManagerDelegate)

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
{
    if (0 < [locations count]) {
        self.lastKnowLocation = locations.lastObject;
        
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading;
{
    self.lastKnownSelfHeading = heading;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
{
    NSLog(@"Core Location error: %@", error);
}

@end
