//
//  SingleAnnotation.h
//  Clutsering
//
//  Created by Stanislaw Pankevich on 05/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MKAnnotation.h>
#import "ClusterAnnotation.h"

@interface SingleAnnotation : NSObject <MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;

@end
