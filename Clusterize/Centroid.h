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
@property (strong, nonatomic) NSMutableArray *points;

- (void)calculateLocation;

@property (nonatomic) CLLocationDistance locationDelta;

@end
