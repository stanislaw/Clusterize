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


            mapRect = MKMapRectMake(0, 0, 100, 100);
            mapPoint = MKMapPointMake(100, 100);

            distance = MKMapRectDistanceToMapPoint(mapRect, mapPoint);

            [[theValue(distance) should] equal:@(0)];


            mapRect = MKMapRectMake(0, 0, 100, 100);
            mapPoint = MKMapPointMake(100, 110);

            distance = MKMapRectDistanceToMapPoint(mapRect, mapPoint);

            [[theValue(distance) should] equal:@(10)];


            mapRect = MKMapRectMake(0, 0, 100, 100);
            mapPoint = MKMapPointMake(0, 0);

            distance = MKMapRectDistanceToMapPoint(mapRect, mapPoint);

            [[theValue(distance) should] equal:@(0)];
        });
    });

    describe(@"MKMapLineSecmentIntersectsLineSegment", ^{
        specify(^{
            MKMapLine line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 100));
            MKMapLine line2 = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 100));

            BOOL intersects = MKMapLineSecmentIntersectsLineSegment(line, line2, NULL, NULL);

            [[theValue(intersects) should] beNo];


            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 100));
            line2 = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 101));

            intersects = MKMapLineSecmentIntersectsLineSegment(line, line2, NULL, NULL);

            [[theValue(intersects) should] beNo];


            line = MKMapLineMake(MKMapPointMake(1, 0), MKMapPointMake(1, 100));
            line2 = MKMapLineMake(MKMapPointMake(1, 1), MKMapPointMake(-1, 1));

            intersects = MKMapLineSecmentIntersectsLineSegment(line, line2, NULL, NULL);

            [[theValue(intersects) should] beYes];


            line = MKMapLineMake(MKMapPointMake(1, 0), MKMapPointMake(1, 100));
            line2 = MKMapLineMake(MKMapPointMake(1, 101), MKMapPointMake(1, 102));

            intersects = MKMapLineSecmentIntersectsLineSegment(line, line2, NULL, NULL);

            [[theValue(intersects) should] beNo];
        });
    });

    describe(@"MKMapLineSecmentIntersectsLineSegment2", ^{
        specify(^{
            MKMapLine line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 100));
            MKMapLine line2 = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 100));

            BOOL intersects = MKMapLineSecmentIntersectsLineSegment2(line, line2);

            [[theValue(intersects) should] beNo];


            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 100));
            line2 = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 101));

            intersects = MKMapLineSecmentIntersectsLineSegment2(line, line2);

            [[theValue(intersects) should] beNo];

            line = MKMapLineMake(MKMapPointMake(1, 0), MKMapPointMake(1, 100));
            line2 = MKMapLineMake(MKMapPointMake(1, 1), MKMapPointMake(-1, 1));

            intersects = MKMapLineSecmentIntersectsLineSegment2(line, line2);

            [[theValue(intersects) should] beYes];
        });
    });

    describe(@"MKMapLineIntersectsRect", ^{
        specify(^{
            MKMapRect mapRect = MKMapRectMake(0, 0, 100, 100);
            MKMapLine line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 100));

            BOOL intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beYes];

            mapRect = MKMapRectMake(0, 0, 100, 100);
            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, -100));

            intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beYes];

            mapRect = MKMapRectMake(0, 0, 100, 100);
            line = MKMapLineMake(MKMapPointMake(-5, 0), MKMapPointMake(-5, 10));

            intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beNo];

            mapRect = MKMapRectMake(-1, -1, 1, 1);
            line = MKMapLineMake(MKMapPointMake(-0.5, -0.5), MKMapPointMake(0, 0));

            intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beYes];

            mapRect = MKMapRectMake(0, 0, 100, 100);
            line = MKMapLineMake(MKMapPointMake(101, 101), MKMapPointMake(30, -10));

            intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beYes];

            mapRect = MKMapRectMake(0, 0, 100, 100);
            line = MKMapLineMake(MKMapPointMake(101, 101), MKMapPointMake(400, 100));

            intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beNo];

            mapRect = MKMapRectMake(-2, 5, 10, 10);
            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 1));

            intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beYes];

            mapRect = MKMapRectMake(-2, 5, 10, 10);
            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(1, 0));

            intersects = MKMapLineIntersectsRect(line, mapRect);

            [[theValue(intersects) should] beNo];
        });
    });
//
    describe(@"MKMapLineIntersectsLine", ^{
        specify(^{
            MKMapLine line = MKMapLineMake(MKMapPointMake(1, 1), MKMapPointMake(2, 2));
            MKMapLine lineSegment = MKMapLineMake(MKMapPointMake(1, 0), MKMapPointMake(2, 1));

            BOOL intersects = MKMapLineIntersectsLineSegment(line, lineSegment, NULL);

            [[theValue(intersects) should] beNo];

            //

            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 2));
            lineSegment = MKMapLineMake(MKMapPointMake(1, 1), MKMapPointMake(-1, 1));

            intersects = MKMapLineIntersectsLineSegment(line, lineSegment, NULL);

            [[theValue(intersects) should] beYes];

            //

            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 2));
            lineSegment = MKMapLineMake(MKMapPointMake(3, 1), MKMapPointMake(1, 1));

            intersects = MKMapLineIntersectsLineSegment(line, lineSegment, NULL);

            [[theValue(intersects) should] beNo];

            //

            line = MKMapLineMake(MKMapPointMake(0, 3), MKMapPointMake(3, 0));
            lineSegment = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(3, 3));

            intersects = MKMapLineIntersectsLineSegment(line, lineSegment, NULL);

            [[theValue(intersects) should] beYes];
        });

    });

    describe(@"MKMapLineSegmentContainsPoint", ^{
        specify(^{
            MKMapLine line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(2, 0));

            BOOL contains = MKMapLineSegmentContainsPoint(line, MKMapPointMake(1, 0));

            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(0, 2));
            contains = MKMapLineSegmentContainsPoint(line, MKMapPointMake(0, 1));

            [[theValue(contains) should] beYes];

            line = MKMapLineMake(MKMapPointMake(6, 0), MKMapPointMake(6, 2));
            contains = MKMapLineSegmentContainsPoint(line, MKMapPointMake(6, 1));

            [[theValue(contains) should] beYes];

            line = MKMapLineMake(MKMapPointMake(6, 0), MKMapPointMake(6, 2));
            contains = MKMapLineSegmentContainsPoint(line, MKMapPointMake(0, 1));

            [[theValue(contains) should] beNo];

            line = MKMapLineMake(MKMapPointMake(0, 0), MKMapPointMake(1, 1));
            contains = MKMapLineSegmentContainsPoint(line, MKMapPointMake(2, 2));

            [[theValue(contains) should] beNo];

        });
    });
});

SPEC_END


