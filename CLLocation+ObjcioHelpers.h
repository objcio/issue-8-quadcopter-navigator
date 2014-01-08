//
//  CLLocation+ObjcioHelpers.h
//  Muninn
//
//  Created by Daniel Eggert on 27/12/2013.
//  Copyright (c) 2013 objc.io. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@class OBJDirection;



@interface CLLocation (ObjcioHelpers)

- (OBJDirection *)directionToLocation:(CLLocation *)otherLocation;

@end



@interface OBJDirection : NSObject

@property (readonly, nonatomic, strong) CLLocation *fromLocation;
@property (readonly, nonatomic, strong) CLLocation *toLocation;

@property (readonly, nonatomic) CLLocationDistance distance;

- (double)heading;

@end
