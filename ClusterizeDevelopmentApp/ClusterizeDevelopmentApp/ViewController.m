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
#import "Centroid.h"
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

    for (int i = 0; i < 7000; i++) {
        CLLocation *randomCoordinate = [self randomLocation];

        [self.annotations addObject:randomCoordinate];
    }

    self.kdTree = [[KDTree alloc] initWithAnnotations:self.annotations];

    self.mapView = mapView;

    [self clusterAnnotationsUsingCenter:nil iteration:0];
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
    [self clusterAnnotationsUsingCenter:nil iteration:0];
}

- (void)clusterAnnotationsUsingCenter:(NSMutableArray *)centroids iteration:(NSInteger)iteration {
    MKMapRect mapRect = self.mapView.visibleMapRect;

    if (centroids == nil) {
        centroids = [NSMutableArray array];

        double widthPercentage = self.gridSize.width / CGRectGetWidth(self.mapView.frame);
        double heightPercentage = self.gridSize.height / CGRectGetHeight(self.mapView.frame);

        double widthInterval = ceil(widthPercentage * mapRect.size.width);
        double heightInterval = ceil(heightPercentage * mapRect.size.height);

        for(int x = mapRect.origin.x; x < mapRect.origin.x + mapRect.size.width; x += widthInterval) {
            for(int y = mapRect.origin.y; y < mapRect.origin.y + mapRect.size.height; y += heightInterval) {
                Centroid *centroid = [[Centroid alloc] init];
                centroid.mapPoint = MKMapPointMake(x, y);
                centroid.numberOfAnnotations = 0;

                [centroids addObject:centroid];
            }
        }
    }

    [self.kdTree annotationsInMapRect:self.mapView.visibleMapRect withRespectToCentroids:centroids];

    [[centroids copy] enumerateObjectsUsingBlock:^(Centroid *centroid, NSUInteger idx, BOOL *stop) {
        if (centroid.numberOfAnnotations == 0) {
            [centroids removeObject:centroid];
        }
    }];

    if (iteration >= 1) {
        NSLog(@"Displaying clusters on iteration and centroids number: (%u; %u)", iteration, centroids.count);

        [self.mapView removeAnnotations:self.mapView.annotations];

        for (Centroid *centroid in centroids) {
            if (centroid.numberOfAnnotations == 0) {
                // Intentionally nothing
            }

            else if (centroid.numberOfAnnotations == 1) {
                SingleAnnotation *singleAnnotation = [[SingleAnnotation alloc] init];
                singleAnnotation.coordinate = [centroid.location coordinate];

                [self.mapView addAnnotation:singleAnnotation];
            }

            else {
                ClusterAnnotation *clusterAnnotation = [[ClusterAnnotation alloc] init];
                clusterAnnotation.coordinate = [centroid location].coordinate;
                clusterAnnotation.title = [[NSNumber numberWithUnsignedInteger:centroid.numberOfAnnotations] stringValue];
                
                [self.mapView addAnnotation:clusterAnnotation];
            }
        }

        NSLog(@"Visible annotations %u", self.mapView.annotations.count);

    } else {
        [self clusterAnnotationsUsingCenter:centroids iteration:(iteration + 1)];
    }
}

- (CLLocation *)randomLocation {
    double (^random_double_with_range)(double min, double max) = ^(double min, double max) {
        unsigned long precision = 10000000;
        return ((double)arc4random_uniform(((max - min) * precision)))/precision + min;
    };

    CLLocationCoordinate2D SWNEBoxes[2] = { CLLocationCoordinate2DMake(55.576792, 37.395973), CLLocationCoordinate2DMake(55.911118, 37.836113) }; // Moscow

    CLLocationDegrees randomCityLatitude = random_double_with_range(SWNEBoxes[0].latitude, SWNEBoxes[1].latitude);
    CLLocationDegrees randomCityLongitude = random_double_with_range(SWNEBoxes[0].longitude, SWNEBoxes[1].longitude);

    return [[CLLocation alloc] initWithLatitude:randomCityLatitude longitude:randomCityLongitude];
}

- (CLLocation *)MoscowLocationKuzminki {
    return [[CLLocation alloc] initWithLatitude:55.699102 longitude:37.743183];
}

- (CGSize)gridSize {
    return CGSizeMake(80, 80);
}

@end
