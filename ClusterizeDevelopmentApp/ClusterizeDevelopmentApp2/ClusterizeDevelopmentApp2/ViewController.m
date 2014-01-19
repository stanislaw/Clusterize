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

static NSString * const DebuggingIdentifier1 = @"1";
static NSString * const DebuggingIdentifier2 = @"2";
static NSString * const DebuggingIdentifier3 = @"3";

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //self.debugging = YES;

    self.annotations = [NSMutableArray array];

    MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    mapView.region = MKCoordinateRegionMakeWithDistance([self MoscowLocation].coordinate, 50000, 50000);
    mapView.delegate = self;

    [self.view addSubview:mapView];

    for (int i = 0; i < 2000; i++) {
        SmartLocation *randomCoordinate = [self randomLocation22];

        [self.annotations addObject:randomCoordinate];
    }

    self.kdTree = [[KDTree alloc] initWithAnnotations:self.annotations];

    self.mapView = mapView;

    for (SmartLocation *location in self.annotations) {
        SingleAnnotation *annotation = [[SingleAnnotation alloc] init];
        annotation.coordinate = location.coordinate;

        //[self.mapView addAnnotation:annotation];
    }
    //[self clusterAnnotations];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *singleAnnotationIdentifier = @"SingleAnnotation";
    static NSString *clusterAnnotationIdentifier = @"ClusterAnnotation";

    if ([annotation isKindOfClass:[SingleAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:singleAnnotationIdentifier];

        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:singleAnnotationIdentifier];
            annotationView.pinColor = MKPinAnnotationColorGreen;
        }

        annotationView.annotation = annotation;

        return annotationView;
    }

    if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:clusterAnnotationIdentifier];

        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:clusterAnnotationIdentifier];
            annotationView.pinColor = MKPinAnnotationColorRed;
            annotationView.canShowCallout = YES;
        }

        annotationView.annotation = annotation;

        return annotationView;
    }

    return nil;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    /* Debugging polygons */
    if ([overlay isKindOfClass:MKPolygon.class]) {
        MKPolygon *polygon = (MKPolygon *)overlay;

        MKPolygonView *polygonView = [[MKPolygonView alloc] initWithPolygon:polygon];


        if ([polygon.title isEqualToString:DebuggingIdentifier1]) {
            polygonView.lineWidth = 2.0;
            polygonView.strokeColor = [UIColor redColor];
            //polygonView.fillColor = [UIColor greenColor];
        } else if ([polygon.title isEqualToString:DebuggingIdentifier2]) {
            polygonView.lineWidth = 1.0;
            polygonView.strokeColor = [UIColor blueColor];
        } else if ([polygon.title isEqualToString:DebuggingIdentifier3]) {
            polygonView.lineWidth = 2.0;
            polygonView.strokeColor = [UIColor greenColor];
        }

        

        return polygonView;
    }
    
    return nil;
}


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    NSLog(@"regionDidChangeAnimated:");

    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    [self clusterAnnotations];
}

- (void)clusterAnnotations {
    MKMapRect mapRect = self.mapView.visibleMapRect;

    NSMutableArray *locations = [NSMutableArray arrayWithArray:[self.kdTree annotationsInMapRect:mapRect]];

    NSMutableArray *locationsToAddAsSingleAnnotations = [locations mutableCopy];

    for (SmartLocation *location in locations) {
        location.annotation = nil;
    }

    NSMutableArray *clusterAnnotations = [NSMutableArray array];

    double widthPercentage = [self annotationSize].width / CGRectGetWidth(self.mapView.bounds);
    double heightPercentage = [self annotationSize].height / CGRectGetHeight(self.mapView.bounds);

    double widthInterval = ceil(widthPercentage * mapRect.size.width);
    double heightInterval = ceil(heightPercentage * mapRect.size.height);


    double offsetXPercentage = [self annotationCenterOffset].x / CGRectGetWidth(self.mapView.bounds);
    double offsetYPercentage = [self annotationCenterOffset].y / CGRectGetHeight(self.mapView.bounds);

    double offsetXInterval = ceil(offsetXPercentage * mapRect.size.width);
    double offsetYInterval = ceil(offsetYPercentage * mapRect.size.height);


    MKMapRect (^mapRectForLocation)(SmartLocation *location) = ^(SmartLocation *location) {
        MKMapPoint locationMapPoint = location.mapPoint;

        MKMapRect mapRect = MKMapRectMake(
            locationMapPoint.x - widthInterval / 2 + offsetXInterval,
            locationMapPoint.y - heightInterval / 2 + offsetYInterval,
            widthInterval,
            heightInterval
        );

        //mapRect = MKMapRectInset(mapRect, - (widthInterval / 4), - (heightInterval / 4));

        return mapRect;
    };

    for (SmartLocation *location in locations) {
        /*
        if (location.annotation) {
            continue;
        }
         */

        MKMapRect locationRect = mapRectForLocation(location);

        MKMapRect locationAroundRect = MKMapRectInset(locationRect, - (locationRect.size.width / 2), - (locationRect.size.height / 2));

        NSArray *relevantLocations = [self.kdTree annotationsInMapRect:locationAroundRect];

        for (SmartLocation *relevantLocation in relevantLocations) {

            if ([location isEqual:relevantLocation]) {
                continue;
            }

            if (relevantLocation.annotation) {
                continue;
            }

            MKMapRect relevantLocationRect = mapRectForLocation(relevantLocation);

            if (MKMapRectIntersectsRect(locationRect, relevantLocationRect)) {
                if (self.debugging) {
                    MKMapPoint points[5];
                    points[0] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y);
                    points[1] = MKMapPointMake(locationRect.origin.x + widthInterval, locationRect.origin.y);
                    points[2] = MKMapPointMake(locationRect.origin.x + widthInterval, locationRect.origin.y + heightInterval);
                    points[3] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y + heightInterval);
                    points[4] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y);

                    MKPolygon *polygon = [MKPolygon polygonWithPoints:points count:5];
                    polygon.title = DebuggingIdentifier1;

                    [self.mapView addOverlay:polygon];


                    MKMapRect locationRect = locationAroundRect;

                    points[0] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y);
                    points[1] = MKMapPointMake(locationRect.origin.x + locationRect.size.width, locationRect.origin.y);
                    points[2] = MKMapPointMake(locationRect.origin.x + locationRect.size.width, locationRect.origin.y + locationRect.size.height);
                    points[3] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y + locationRect.size.height);
                    points[4] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y);

                    polygon = [MKPolygon polygonWithPoints:points count:5];
                    polygon.title = DebuggingIdentifier2;

                    [self.mapView addOverlay:polygon];

                    locationRect = relevantLocationRect;

                    points[0] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y);
                    points[1] = MKMapPointMake(locationRect.origin.x + locationRect.size.width, locationRect.origin.y);
                    points[2] = MKMapPointMake(locationRect.origin.x + locationRect.size.width, locationRect.origin.y + locationRect.size.height);
                    points[3] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y + locationRect.size.height);
                    points[4] = MKMapPointMake(locationRect.origin.x, locationRect.origin.y);
                    
                    polygon = [MKPolygon polygonWithPoints:points count:5];
                    polygon.title = DebuggingIdentifier3;
                    
                    [self.mapView addOverlay:polygon];
                }

                if (location.annotation == nil && relevantLocation.annotation == nil) {
                    ClusterAnnotation *clusterAnnotation = [[ClusterAnnotation alloc] init];
                    clusterAnnotation.locations = [NSMutableSet set];

                    [clusterAnnotation.locations addObject:location];
                    [clusterAnnotation.locations addObject:relevantLocation];

                    [locationsToAddAsSingleAnnotations removeObject:location];
                    [locationsToAddAsSingleAnnotations removeObject:relevantLocation];

                    location.annotation = clusterAnnotation;
                    relevantLocation.annotation = clusterAnnotation;

                    [clusterAnnotations addObject:clusterAnnotation];
                } else if (location.annotation && relevantLocation.annotation == nil) {
                    ClusterAnnotation *clusterAnnotation = location.annotation;

                    [clusterAnnotation calculateCoordinate];

                    SmartLocation *centroidLocation = [[SmartLocation alloc] initWithCoordinate:clusterAnnotation.coordinate];

                    MKMapRect centroidRect = mapRectForLocation(centroidLocation);

                    if (MKMapRectIntersectsRect(centroidRect, relevantLocationRect)) {
                        [clusterAnnotation.locations addObject:relevantLocation];

                        relevantLocation.annotation = clusterAnnotation;

                        [locationsToAddAsSingleAnnotations removeObject:relevantLocation];
                    }
                }
            }
        }

        //break;
    }

    int totalAnnotations = 0;

    for (ClusterAnnotation *clusterAnnotation in clusterAnnotations) {
        [clusterAnnotation calculateCoordinate];
        totalAnnotations += clusterAnnotation.locations.count;
    }

    for (SmartLocation *location in locationsToAddAsSingleAnnotations) {
        if (location.annotation == nil) {
            totalAnnotations++;
            SingleAnnotation *singleAnnotation = [[SingleAnnotation alloc] init];
            singleAnnotation.coordinate = location.coordinate;
            [self.mapView addAnnotation:singleAnnotation];
        }
    }

    [self.mapView addAnnotations:clusterAnnotations];

    NSLog(@"Total %d, clusters: %u, red rects", totalAnnotations, clusterAnnotations.count);
}

- (SmartLocation *)randomLocation22 {
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
    return CGPointMake(0, -19.5);
}

- (CGSize)annotationSize {
    return CGSizeMake(16, 39);
}

@end
