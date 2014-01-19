//
//  SmartLocation.h
//  ClusterizeDevelopmentApp2
//
//  Created by Stanislaw Pankevich on 19/01/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKGeometry.h>

@interface SmartLocation : CLLocation

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@property (nonatomic, readonly) MKMapPoint mapPoint;
@property (nonatomic) id annotation;

@end
