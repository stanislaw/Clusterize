//
//  SmartLocation.h
//  ClusterizeDevelopmentApp2
//
//  Created by Stanislaw Pankevich on 19/01/14.
//  Copyright (c) 2014 Stanislaw Pankevich. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface SmartLocation : CLLocation

@property (nonatomic) NSValue *_annotationPointInMapView;
@property (nonatomic) id annotation;

@end
