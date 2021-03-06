//
//  SmartLocation.m
//  ClusterizeDevelopmentApp2
//
//  Created by Stanislaw Pankevich on 19/01/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import "SmartLocation.h"

@implementation SmartLocation

@synthesize mapPoint = _mapPoint;

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (CLLocationCoordinate2DIsValid(coordinate) == NO) {
        abort();
    }
    
    self = [super initWithLatitude:coordinate.latitude longitude:coordinate.longitude];

    _mapPoint = MKMapPointForCoordinate(self.coordinate);

    return self;
}

@end
