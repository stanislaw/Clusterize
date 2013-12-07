//
//  ClusterizeTests.m
//  ClusterizeTests
//
//  Created by Stanislaw Pankevich on 07/12/13.
//  Copyright (c) 2013 Stanislaw Pankevich. All rights reserved.
//

#import <Kiwi/Kiwi.h>

#import "Geometry_Unused.h"

SPEC_BEGIN(Clusterize_Unused_Specs)

describe(@"Geometry", ^{
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


