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

    self.mapPoint = MKMapPointMake(0, 0);
    self.squaredMapPoint = MKMapPointMake(0, 0);

    [self invalidateAccumulatedData];

    return self;
}

- (void)calculateLocationBasedOnAccumulatedData {
    if (self.numberOfAnnotations > 0) {
        self.mapPoint = MKMapPointMake(self.sumOfMapPoints.x / self.numberOfAnnotations, self.sumOfMapPoints.y / self.numberOfAnnotations);
        self.squaredMapPoint = MKMapPointMake(pow(self.mapPoint.x, 2), pow(self.mapPoint.y, 2));

        CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(self.mapPoint);

        CLLocation *oldLocation = self.location;

        self.location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];

        if (oldLocation) {
            //self.delta = pow(coordinate.latitude - oldLocation.coordinate.latitude, 2) + pow(coordinate.longitude - oldLocation.coordinate.longitude, 2);

            //self.delta = [self.location distanceFromLocation:oldLocation];
        }
    }
}

- (void)invalidateAccumulatedData {
    self.numberOfAnnotations = 0;
    self.sumOfMapPoints = MKMapPointMake(0, 0);
    self.delta = DBL_MAX;
}

- (void)setLocation:(CLLocation *)location {
    _location = [location copy];
}

@end
