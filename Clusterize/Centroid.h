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

@property (strong, nonatomic) CLLocation *location;
@property (nonatomic, readonly) MKMapPoint mapPoint;

- (void)calculateLocationBasedOnAccumulatedData;
- (void)invalidateAccumulatedData;

@property (nonatomic) CLLocationDistance locationDelta;

@property (nonatomic) NSUInteger numberOfAnnotations;
@property (nonatomic) CLLocationCoordinate2D totalCoordinate;

@end
