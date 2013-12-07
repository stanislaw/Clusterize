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
    
    self.points = [NSMutableArray array];

    return self;
}

- (void)calculateLocation {
    if (self.points.count == 0) return;

    CLLocationDegrees minLat = INT_MAX;
    CLLocationDegrees minLng = INT_MAX;
    CLLocationDegrees maxLat = -INT_MAX;
    CLLocationDegrees maxLng = -INT_MAX;

    CLLocationDegrees totalLat = 0;
    CLLocationDegrees totalLng = 0;

    for(id <MKAnnotation> a in self.points){

        CLLocationDegrees lat = [a coordinate].latitude;
        CLLocationDegrees lng = [a coordinate].longitude;

        minLat = MIN(minLat, lat);
        minLng = MIN(minLng, lng);
        maxLat = MAX(maxLat, lat);
        maxLng = MAX(maxLng, lng);

        totalLat += lat;
        totalLng += lng;
    }

    self.location = [[CLLocation alloc] initWithLatitude:(totalLat / self.points.count) longitude:(totalLng / self.points.count)];
}

- (void)setLocation:(CLLocation *)location {
    if (_location != nil) {
        self.locationDelta = [_location distanceFromLocation:location];
    }
    
    _location = [location copy];
}

@end
