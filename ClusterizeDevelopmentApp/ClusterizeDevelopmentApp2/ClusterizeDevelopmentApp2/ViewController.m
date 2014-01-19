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
    mapView.region = MKCoordinateRegionMakeWithDistance([self MoscowLocation].coordinate, 50000, 50000);
    mapView.delegate = self;

    [self.view addSubview:mapView];

    for (int i = 0; i < 1000; i++) {
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

    double widthPercentage = [self annotationSize].width / CGRectGetWidth(self.mapView.frame);
    double heightPercentage = [self annotationSize].height / CGRectGetHeight(self.mapView.frame);

    double widthInterval = ceil(widthPercentage * self.mapView.visibleMapRect.size.width);
    double heightInterval = ceil(heightPercentage * self.mapView.visibleMapRect.size.height);


    double offsetXPercentage = [self annotationCenterOffset].x / CGRectGetWidth(self.mapView.frame);
    double offsetYPercentage = [self annotationCenterOffset].y / CGRectGetHeight(self.mapView.frame);

    double offsetXInterval = ceil(offsetXPercentage * self.mapView.visibleMapRect.size.width);
    double offsetYInterval = ceil(offsetYPercentage * self.mapView.visibleMapRect.size.height);


    MKMapRect (^mapRectForLocation)(SmartLocation *location) = ^(SmartLocation *location) {
        MKMapPoint locationMapPoint = location.mapPoint;

        MKMapRect mapRect = MKMapRectMake(
            locationMapPoint.x - widthInterval / 2 + offsetXInterval,
            locationMapPoint.y - heightInterval / 2 + offsetYInterval,
            widthInterval,
            heightInterval
        );

        return mapRect;
    };

    NSLog(@"WTF %f %f", widthInterval, heightInterval);

    for (SmartLocation *location in locations) {

        MKMapRect locationRect = mapRectForLocation(location);

        MKMapRect locationAroundRect = MKMapRectInset(locationRect, - (widthInterval / 2), - (heightInterval / 2));

        NSArray *relevantLocations = [self.kdTree annotationsInMapRect:locationAroundRect];

        for (SmartLocation *relevantLocation in relevantLocations) {

            if ([location isEqual:relevantLocation]) {
                continue;
            }

            MKMapRect relevantLocationRect = mapRectForLocation(relevantLocation);

            if (MKMapRectIntersectsRect(locationRect, relevantLocationRect)) {
                if (location.annotation) {
                    relevantLocation.annotation = location.annotation;
                } else {
                    ClusterAnnotation *clusterAnnotation = [[ClusterAnnotation alloc] init];
                    clusterAnnotation.coordinate = location.coordinate;
                    location.annotation = clusterAnnotation;

                    relevantLocation.annotation = location.annotation;

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

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(randomCityLatitude, randomCityLongitude);

    return [[SmartLocation alloc] initWithCoordinate:coordinate];
}

- (SmartLocation *)MoscowLocation {
    return [[SmartLocation alloc] initWithLatitude:55.753001 longitude:37.615167];
}

// (-16 -19.5; 32 39);
- (CGPoint)annotationCenterOffset {
    return CGPointMake(0, -20);
}

- (CGSize)annotationSize {
    return CGSizeMake(32, 40);
}

@end
