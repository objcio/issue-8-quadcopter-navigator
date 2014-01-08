//
//  RemoteControlCommand.m
//  ARDrone
//
//  Created by Daniel Eggert on 30/12/2013.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "RemoteControlCommand.h"



@implementation RemoteControlCommand

+ (BOOL)supportsSecureCoding;
{
    return YES;
}

+ (instancetype)commandFromNetworkData:(NSData *)data;
{
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    unarchiver.requiresSecureCoding = YES;
    RemoteControlCommand *result = [unarchiver decodeObjectOfClass:self forKey:@"command"];
    return result;
}

- (NSData *)encodeAsNetworkData;
{
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:self forKey:@"command"];
    [archiver finishEncoding];
    return data;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeDouble:self.coordinate.latitude forKey:@"coordinate.latitude"];
    [coder encodeDouble:self.coordinate.longitude forKey:@"coordinate.longitude"];
    [coder encodeBool:self.stop forKey:@"stop"];
}

- (id)initWithCoder:(NSCoder *)coder;
{
    self = [super init];
    if (self != nil) {
        CLLocationCoordinate2D coordinate = {};
        coordinate.latitude = [coder decodeDoubleForKey:@"coordinate.latitude"];
        coordinate.longitude = [coder decodeDoubleForKey:@"coordinate.longitude"];
        self.coordinate = coordinate;
        self.stop = [coder decodeBoolForKey:@"stop"];
    }
    return self;
}

- (NSString *)description;
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> lat %g, long %g",
                                    self.class, self, self.coordinate.latitude, self.coordinate.longitude];
    if (self.stop) {
        [description appendString:@" Stop"];
    }
    return description;
}

@end
