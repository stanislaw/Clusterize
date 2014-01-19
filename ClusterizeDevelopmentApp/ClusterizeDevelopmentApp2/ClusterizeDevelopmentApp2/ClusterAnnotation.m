//
//  ClusterAnnotation.m
//  Clutsering
//
//  Created by Stanislaw Pankevich on 05/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "ClusterAnnotation.h"
#import "SmartLocation.h"

@implementation ClusterAnnotation

@synthesize coordinate = _coordinate;

- (instancetype)init {
    self = [super init];

    return self;
}

- (void)calculateCoordinate {
    CLLocationCoordinate2D centroidPoint = CLLocationCoordinate2DMake(0, 0);

    for (SmartLocation *location in self.locations) {
        centroidPoint.latitude += location.coordinate.latitude;
        centroidPoint.longitude += location.coordinate.longitude;
    }

    centroidPoint.latitude = centroidPoint.latitude / self.locations.count;
    centroidPoint.longitude = centroidPoint.longitude / self.locations.count;


    /*
    if (CLLocationCoordinate2DIsValid(centroidPoint) == NO) {
        NSLog(@"Wrong centroid coordinate %f %f", centroidPoint.latitude, centroidPoint.longitude);

        abort();
    }
     */


    self.title = [NSString stringWithFormat:@"Annotations: %u", self.locations.count];
    
    _coordinate = centroidPoint;
}


@end
