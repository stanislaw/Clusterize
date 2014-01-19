//
//  ViewController.m
//  Clutsering
//
//  Created by Stanislaw Pankevich on 05/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import "ViewController.h"
#import "SingleAnnotation.h"
#import "ClusterAnnotation.h"
#import "SmartLocation.h"
#import "Geometry.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.annotations = [NSMutableArray array];

    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    mapView.region = MKCoordinateRegionMakeWithDistance([self MoscowLocationKuzminki].coordinate, 50000, 50000);
    mapView.delegate = self;

    [self.view addSubview:mapView];

    for (int i = 0; i < 50; i++) {
        SmartLocation *randomCoordinate = [self randomLocation];

        [self.annotations addObject:randomCoordinate];
    }

    self.kdTree = [[KDTree alloc] initWithAnnotations:self.annotations];

    self.mapView = mapView;

    [self clusterAnnotations];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *singleAnnotationIdentifier = @"SingleAnnotation";
    static NSString *clusterAnnotationIdentifier = @"ClusterAnnotation";

    if ([annotation isKindOfClass:[SingleAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:singleAnnotationIdentifier];

        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:singleAnnotationIdentifier];
            annotationView.pinColor = MKPinAnnotationColorGreen;
        } else {
            annotationView.annotation = annotation;
        }

        return annotationView;
    }

    if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:clusterAnnotationIdentifier];

        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:clusterAnnotationIdentifier];
            annotationView.pinColor = MKPinAnnotationColorPurple;
            annotationView.canShowCallout = YES;
        } else {
            annotationView.annotation = annotation;
        }

        return annotationView;
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self clusterAnnotations];
}

- (void)clusterAnnotations {
    [self.mapView removeAnnotations:self.mapView.annotations];

    MKMapRect mapRect = self.mapView.visibleMapRect;

    NSMutableArray *locations = [NSMutableArray arrayWithArray:[self.kdTree annotationsInMapRect:mapRect]];

    for (SmartLocation *location in locations) {
        location.annotation = nil;
    }

    NSMutableArray *clusterAnnotations = [NSMutableArray array];

    for (int i = 0; i < locations.count; i++) {
        for (int j = 0; j < locations.count; j++) {

            SmartLocation *c1 = locations[i];
            SmartLocation *c2 = locations[j];

            if ([c1 isEqual:c2]) {
                continue;
            }

            //if (!c1._annotationPointInMapView) {
                c1._annotationPointInMapView = [NSValue valueWithCGPoint:[self.mapView convertCoordinate:c1.coordinate
                                                                                           toPointToView:self.mapView]];
            //}

            //if (!c2._annotationPointInMapView) {
                c2._annotationPointInMapView = [NSValue valueWithCGPoint:[self.mapView convertCoordinate:c2.coordinate
                                                                                           toPointToView:self.mapView]];
            //}

            CGPoint p1 = [c1._annotationPointInMapView CGPointValue];
            CGPoint p2 = [c2._annotationPointInMapView CGPointValue];

            CGRect r1 = CGRectMake(p1.x - self.annotationSize.width + self.annotationCenterOffset.x,
                                   p1.y - self.annotationSize.height + self.annotationCenterOffset.y,
                                   self.annotationSize.width,
                                   self.annotationSize.height);

            CGRect r2 = CGRectMake(p2.x - self.annotationSize.width + self.annotationCenterOffset.x,
                                   p2.y - self.annotationSize.height + self.annotationCenterOffset.y,
                                   self.annotationSize.width,
                                   self.annotationSize.height);

            if (CGRectIntersectsRect(r1, r2)) {
                if (c1.annotation) {
                    c2.annotation = c1.annotation;
                } else {
                    ClusterAnnotation *clusterAnnotation = [[ClusterAnnotation alloc] init];
                    clusterAnnotation.coordinate = c1.coordinate;
                    c1.annotation = clusterAnnotation;

                    c2.annotation = c1.annotation;

                    [clusterAnnotations addObject:clusterAnnotation];
                }
            } else {

            }
        }
    }

    [self.mapView addAnnotations:clusterAnnotations];

    for (SmartLocation *location in locations) {
        if (location.annotation == nil) {
            SingleAnnotation *singleAnnotation = [[SingleAnnotation alloc] init];
            singleAnnotation.coordinate = location.coordinate;
            [self.mapView addAnnotation:singleAnnotation];
        }
    }
}

- (SmartLocation *)randomLocation {
    double (^random_double_with_range)(double min, double max) = ^(double min, double max) {
        unsigned long precision = 10000000;
        return ((double)arc4random_uniform(((max - min) * precision)))/precision + min;
    };

    CLLocationCoordinate2D SWNEBoxes[2] = { CLLocationCoordinate2DMake(55.576792, 37.395973), CLLocationCoordinate2DMake(55.911118, 37.836113) }; // Moscow

    CLLocationDegrees randomCityLatitude = random_double_with_range(SWNEBoxes[0].latitude, SWNEBoxes[1].latitude);
    CLLocationDegrees randomCityLongitude = random_double_with_range(SWNEBoxes[0].longitude, SWNEBoxes[1].longitude);

    return [[SmartLocation alloc] initWithLatitude:randomCityLatitude longitude:randomCityLongitude];
}

- (SmartLocation *)MoscowLocationKuzminki {
    return [[SmartLocation alloc] initWithLatitude:55.699102 longitude:37.743183];
}

- (CGPoint)annotationCenterOffset {
    return CGPointMake(0, 20);
}

- (CGSize)annotationSize {
    return CGSizeMake(20, 40);
}

- (CGSize)gridSize {
    return CGSizeMake(80, 80);
}

@end
