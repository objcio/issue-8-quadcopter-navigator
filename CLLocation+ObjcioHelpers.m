//
//  CLLocation+ObjcioHelpers.m
//  Muninn
//
//  Created by Daniel Eggert on 27/12/2013.
//  Copyright (c) 2013 objc.io. All rights reserved.
//

#import "CLLocation+ObjcioHelpers.h"



@interface OBJDirection ()

- (instancetype)initWithFromLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation;

@end



@implementation OBJDirection

- (instancetype)initWithFromLocation:(CLLocation *)fromLocation toLocation:(CLLocation *)toLocation;
{
    self = [super init];
    if (self != nil) {
        // We cheat here and use plane geometry (valid for small areas on the Earth's surface)
        _fromLocation = fromLocation;
        _toLocation = toLocation;
        _distance = [self.fromLocation distanceFromLocation:self.toLocation];
    }
    return self;
}

static double radiansToDegrees(double x)
{
    return (x * 180.0 * M_1_PI);
}

- (double)heading;
{
    double y = self.toLocation.coordinate.longitude - self.fromLocation.coordinate.longitude;
    double x = self.toLocation.coordinate.latitude - self.fromLocation.coordinate.latitude;
    
    double degree = radiansToDegrees(atan2(y, x));
    return fmod(degree + 360., 360.);
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"distance: %g  angle: %d",
            self.distance, (int) round(self.heading)];
}

@end



@implementation CLLocation (ObjcioHelpers)

- (OBJDirection *)directionToLocation:(CLLocation *)otherLocation;
{
    return [[OBJDirection alloc] initWithFromLocation:self toLocation:otherLocation];
}

@end
