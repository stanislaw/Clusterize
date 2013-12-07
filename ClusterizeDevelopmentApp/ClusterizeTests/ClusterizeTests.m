//
//  ClusterizeTests.m
//  ClusterizeTests
//
//  Created by Stanislaw Pankevich on 07/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Kiwi/Kiwi.h>

#import "Geometry.h"

SPEC_BEGIN(ClusterizeSpecs)

describe(@"Geometry", ^{
    describe(@"MKMapRectDistanceToMapPoint", ^{
        specify(^{
            MKMapRect mapRect = MKMapRectMake(0, 0, 100, 100);
            MKMapPoint mapPoint = MKMapPointMake(50, 50);

            CLLocationDistance distance = MKMapRectDistanceToMapPoint(mapRect, mapPoint);

            [[theValue(distance) should] equal:@(0)];
        });

        specify(^{
            MKMapRect mapRect = MKMapRectMake(0, 0, 100, 100);
            MKMapPoint mapPoint = MKMapPointMake(100, 100);

            CLLocationDistance distance = MKMapRectDistanceToMapPoint(mapRect, mapPoint);

            [[theValue(distance) should] equal:@(0)];
        });

        specify(^{
            MKMapRect mapRect = MKMapRectMake(0, 0, 100, 100);
            MKMapPoint mapPoint = MKMapPointMake(100, 110);

            CLLocationDistance distance = MKMapRectDistanceToMapPoint(mapRect, mapPoint);

            [[theValue(distance) should] equal:@(10)];
        });

        specify(^{
            MKMapRect mapRect = MKMapRectMake(0, 0, 100, 100);
            MKMapPoint mapPoint = MKMapPointMake(0, 0);

            CLLocationDistance distance = MKMapRectDistanceToMapPoint(mapRect, mapPoint);

            [[theValue(distance) should] equal:@(0)];
        });
    });

    describe(@"MKMapLineIntersectsRect", ^{
        specify(^{
            MKMapRect mapRect = MKMapRectMake(0, 0, 100, 100);
            MKMapLine line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 100));

            BOOL intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beYes];
        });

        specify(^{
            MKMapRect mapRect = MKMapRectMake(0, 0, 100, 100);
            MKMapLine line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, -100));

            BOOL intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beYes];
        });

        specify(^{
            MKMapRect mapRect = MKMapRectMake(0, 0, 100, 100);
            MKMapLine line = MKMapLineMake(MKMapPointMake(-5, 0), MKMapPointMake(-5, 10));

            BOOL intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beNo];
        });

        specify(^{
            MKMapRect mapRect = MKMapRectMake(-1, -1, 1, 1);
            MKMapLine line = MKMapLineMake(MKMapPointMake(-0.5, -0.5), MKMapPointMake(0, 0));

            BOOL intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beYes];
        });
    });
    
});

SPEC_END


