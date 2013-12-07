//
//  ViewController.h
//  Clutsering
//
//  Created by Stanislaw Pankevich on 05/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "KDTree.h"

@interface ViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) NSMutableArray *annotations;

@property (readonly) CGSize gridSize;

@property (strong, nonatomic) NSMutableArray *oldLocations;

@property (nonatomic) KDTree *kdTree;

@end
