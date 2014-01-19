//
//  ClusterAnnotation.h
//  Clutsering
//
//  Created by Stanislaw Pankevich on 05/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKGeometry.h>

@interface ClusterAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
- (void)calculateCoordinate;

@property (copy, nonatomic) NSString *title;

@property (nonatomic) NSMutableSet *locations;

@end
