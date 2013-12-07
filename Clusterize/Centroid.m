//
//  Centroid.m
//  Clutsering
//
//  Created by Stanislaw Pankevich on 05/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "Centroid.h"

@implementation Centroid

- (instancetype)init {
    self = [super init];

    if (self == nil) return nil;

    [self invalidateAccumulatedData];
    
    return self;
}

- (void)calculateLocationBasedOnAccumulatedData {
    if (self.numberOfAnnotations > 0) {
        self.mapPoint = MKMapPointMake(self.sumOfMapPoints.x / self.numberOfAnnotations, self.sumOfMapPoints.y / self.numberOfAnnotations);
        CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(self.mapPoint);

        self.location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    }
}

- (void)invalidateAccumulatedData {
    self.numberOfAnnotations = 0;
    self.sumOfMapPoints = MKMapPointMake(0, 0);
}

- (void)setLocation:(CLLocation *)location {
    if (_location != nil) {
        self.locationDelta = [_location distanceFromLocation:location];
    }
    
    _location = [location copy];
}

@end
