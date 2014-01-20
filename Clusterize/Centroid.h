//
//  Centroid.h
//  Clutsering
//
//  Created by Stanislaw Pankevich on 05/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface Centroid : NSObject

@property (readonly, nonatomic) CLLocation *location;
@property (nonatomic) MKMapPoint mapPoint;
@property (nonatomic) MKMapPoint squaredMapPoint;


- (void)calculateLocationBasedOnAccumulatedData;
- (void)invalidateAccumulatedData;

@property (nonatomic) NSUInteger numberOfAnnotations;
@property (nonatomic) MKMapPoint sumOfMapPoints;
@property (nonatomic) CLLocationDegrees delta;

@end
