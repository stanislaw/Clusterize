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
    self.sumOfMapPoints = MKMapPointMake(0, 0);
    self.numberOfAnnotations = 0;

    return self;
}

- (void)calculateCoordinate {
    MKMapPoint centroidMapPoint = MKMapPointMake(self.sumOfMapPoints.x / self.numberOfAnnotations, self.sumOfMapPoints.y / self.numberOfAnnotations);

    CLLocationCoordinate2D centroidPoint = MKCoordinateForMapPoint(centroidMapPoint);

    self.title = [NSString stringWithFormat:@"Annotations: %u", self.numberOfAnnotations];
    
    _coordinate = centroidPoint;
}


@end
