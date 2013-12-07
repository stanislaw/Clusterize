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

    self.totalCoordinate = CLLocationCoordinate2DMake(0, 0);

    return self;
}

- (void)calculateLocationBasedOnAccumulatedData {
    if (self.numberOfAnnotations > 0) {
        self.location = [[CLLocation alloc] initWithLatitude:(self.totalCoordinate.latitude / self.numberOfAnnotations) longitude:(self.totalCoordinate.longitude / self.numberOfAnnotations)];
    }
}

- (void)invalidateAccumulatedData {
    self.numberOfAnnotations = 0;
    self.totalCoordinate = CLLocationCoordinate2DMake(0, 0);
}

- (void)setLocation:(CLLocation *)location {
    if (_location != nil) {
        self.locationDelta = [_location distanceFromLocation:location];
    }
    
    _location = [location copy];
}

- (MKMapPoint)mapPoint {
    return MKMapPointForCoordinate(self.location.coordinate);
}

@end
