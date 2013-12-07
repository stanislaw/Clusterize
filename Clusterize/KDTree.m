//
// Copyright 2012 Bryan Bonczek
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "KDTree.h"
#import "KDTreeNode.h"

#import "Centroid.h"

#import "Geometry.h"

@interface KDTree ()

@property (nonatomic) KDTreeNode *root;
@property (nonatomic, readwrite) NSSet *annotations;

@end

@implementation KDTree

- (id)initWithAnnotations:(NSArray *)annotations {

    self = [super init];

    if (self == nil) return nil;

    self.annotations = [NSSet setWithArray:annotations];
    self.root = [self buildTree:annotations level:0 mapRect:MKMapRectWorld];

    return self;
}

#pragma mark - Search

- (NSArray *)annotationsInMapRect:(MKMapRect)rect {

    NSMutableArray *result = [NSMutableArray array];

    [self doSearchInMapRect:rect
         mutableAnnotations:result
                    curNode:self.root
                   curLevel:0];

    return result;
}

- (NSArray *)annotationsInMapRect:(MKMapRect)rect withRespectToCentroids:(NSMutableArray *)centroids {

    NSMutableArray *result = [NSMutableArray array];

    for (Centroid *centroid in centroids) {
        [centroid invalidateAccumulatedData];
    }

    [self doSearchInMapRect:rect
         mutableAnnotations:result
                    curNode:self.root
                   curLevel:0
     withRespectToCentroids:centroids];

    [centroids enumerateObjectsUsingBlock:^(Centroid *centroid, NSUInteger idx, BOOL *stop) {
        [centroid calculateLocationBasedOnAccumulatedData];
    }];

    return result;
}

- (void)doSearchInMapRect:(MKMapRect)mapRect
       mutableAnnotations:(NSMutableArray *)annotations
                  curNode:(KDTreeNode *)curNode
                 curLevel:(NSInteger)level
   withRespectToCentroids:(NSMutableArray *)centroids {

    NSParameterAssert(curNode);

    if (curNode.annotation) {
        NSAssert(curNode.numberOfAnnotations == 1, nil);
        
        __block CLLocationDistance minimalDistance = NSUIntegerMax;
        __block NSUInteger bestCenterIndex = NSNotFound;

        CLLocation *location = curNode.annotation;

        [centroids enumerateObjectsUsingBlock:^(Centroid *centroid, NSUInteger idx, BOOL *stop) {
            CLLocationDistance distanceBeetweenCenterAndPoint = [location distanceFromLocation:centroid.location];

            if (distanceBeetweenCenterAndPoint < minimalDistance) {
                minimalDistance = distanceBeetweenCenterAndPoint;
                bestCenterIndex = idx;
            }
        }];

        if (bestCenterIndex != NSNotFound) {
            Centroid *bestCentroidFound = [centroids objectAtIndex:bestCenterIndex];

            bestCentroidFound.totalCoordinate = CLLocationCoordinate2DMake(bestCentroidFound.totalCoordinate.latitude + location.coordinate.latitude, bestCentroidFound.totalCoordinate.longitude + location.coordinate.longitude);

            bestCentroidFound.numberOfAnnotations++;
        } else {
            abort();
        }

        return;
    }

    if (MKMapRectIntersectsRect(mapRect, curNode.mapRect) == NO) {
        return;
    }

    __block BOOL currentNodeAlreadyContainsCentroid = NO;
    __block CLLocationDistance minimalDistanceBeetweenNodeAndCentroid = NSUIntegerMax;
    __block NSUInteger candidateCentroidIndex = NSNotFound;

    [centroids enumerateObjectsUsingBlock:^(Centroid *centroid, NSUInteger centroidIndex, BOOL *stop) {
        CLLocationDistance distanceBeetweenNodeAndCentroid = MKMapRectDistanceToMapPoint(curNode.mapRect, centroid.mapPoint);

        if (distanceBeetweenNodeAndCentroid == 0) {
            if (currentNodeAlreadyContainsCentroid) {
                *stop = YES;
                candidateCentroidIndex = NSNotFound;
                return;
            } else {
                minimalDistanceBeetweenNodeAndCentroid = 0;
                currentNodeAlreadyContainsCentroid = YES;
            }
        }

        // TODO check one center exist!
        else if (minimalDistanceBeetweenNodeAndCentroid > distanceBeetweenNodeAndCentroid) {
            minimalDistanceBeetweenNodeAndCentroid = distanceBeetweenNodeAndCentroid;
            candidateCentroidIndex = centroidIndex;
        }
    }];

    if (candidateCentroidIndex != NSNotFound) {
        Centroid *candidateCentroid = [centroids objectAtIndex:candidateCentroidIndex];

        __block BOOL candidateCentroidDominatesAllOtherCentroids = YES;

        [centroids enumerateObjectsUsingBlock:^(Centroid *centroid, NSUInteger centroidIndex, BOOL *stop) {
            if (centroidIndex == candidateCentroidIndex) {
                return;
            }

            MKMapPoint firstDecisionLinePoint = MKMapPointMake((candidateCentroid.mapPoint.x + centroid.mapPoint.x) / 2, (candidateCentroid.mapPoint.y + centroid.mapPoint.y) / 2);

            double decisionLineSlope = -1 * (centroid.mapPoint.x - candidateCentroid.mapPoint.x) * (centroid.mapPoint.y - candidateCentroid.mapPoint.y);

            double b = firstDecisionLinePoint.y - decisionLineSlope * firstDecisionLinePoint.x;

            MKMapPoint secondDecisionLinePoint = MKMapPointMake(0, b);

            MKMapLine decisionLine = MKMapLineMake(firstDecisionLinePoint, secondDecisionLinePoint);

            if (MKMapLineIntersectsRect(decisionLine, curNode.mapRect)) {
                candidateCentroidDominatesAllOtherCentroids = NO;
                *stop = YES;
            }
        }];

        if (candidateCentroidDominatesAllOtherCentroids) {
            candidateCentroid.numberOfAnnotations += curNode.numberOfAnnotations;

            candidateCentroid.totalCoordinate = CLLocationCoordinate2DMake(
                candidateCentroid.totalCoordinate.latitude + curNode.totalCoordinate.latitude,
                candidateCentroid.totalCoordinate.longitude + curNode.totalCoordinate.longitude
            );

            return;
        }
    }

    [self doSearchInMapRect:mapRect mutableAnnotations:annotations curNode:curNode.left curLevel:(level + 1) withRespectToCentroids:centroids];

    [self doSearchInMapRect:mapRect mutableAnnotations:annotations curNode:curNode.right curLevel:(level + 1) withRespectToCentroids:centroids];
}


- (void)doSearchInMapRect:(MKMapRect)mapRect
       mutableAnnotations:(NSMutableArray *)annotations
                  curNode:(KDTreeNode *)curNode
                 curLevel:(NSInteger)level {

    if (curNode == nil) {
        abort();
    }

    if (curNode.annotation) {
        if (MKMapRectContainsPoint(mapRect, MKMapPointForCoordinate(curNode.annotation.coordinate))) {
            [annotations addObject:curNode.annotation];
        }

        return;
    }

    MKMapPoint mapPoint = curNode.medianMapPoint;

    BOOL useY = (BOOL)(level % 2);

    float val = (useY ? mapPoint.y : mapPoint.x);
    float minVal = (useY ? MKMapRectGetMinY(mapRect) : MKMapRectGetMinX(mapRect));
    float maxVal = (useY ? MKMapRectGetMaxY(mapRect) : MKMapRectGetMaxX(mapRect));

    if (maxVal < val) {
        [self doSearchInMapRect:mapRect
             mutableAnnotations:annotations
                        curNode:curNode.left
                       curLevel:(level + 1)];
    }

    else if (minVal > val){
        [self doSearchInMapRect:mapRect
             mutableAnnotations:annotations
                        curNode:curNode.right
                       curLevel:(level + 1)];
    }

    else {

        [self doSearchInMapRect:mapRect
             mutableAnnotations:annotations
                        curNode:curNode.left
                       curLevel:(level + 1)];

        [self doSearchInMapRect:mapRect
             mutableAnnotations:annotations
                        curNode:curNode.right
                       curLevel:(level + 1)];
    }

}

- (KDTreeNode *)buildTree:(NSArray *)annotations level:(NSInteger)curLevel mapRect:(MKMapRect)mapRect {
    NSInteger count = [annotations count];

    if (count == 0) {
        return nil;
    }

    KDTreeNode *treeNode = [[KDTreeNode alloc] init];
    treeNode.numberOfAnnotations = count;

    if (count == 1) {
        treeNode.annotation = [annotations firstObject];

        return treeNode;
    }

    BOOL sortY = (BOOL)(curLevel % 2);

    NSArray *sortedAnnotations = [self sortedAnnotations:annotations sortY:sortY];

    MKMapRect treeNodeRect = mapRect;

    if (curLevel == 0) {
        treeNodeRect = [self mapRectThatFitsAnnotations:sortedAnnotations];
    }

    treeNode.mapRect = treeNodeRect;

    if (MKMapRectContainsRect(mapRect, treeNode.mapRect) == NO) {
        abort();
    }
    
    // Median map point
    NSInteger medianIdx = [sortedAnnotations count] / 2;
    CLLocation *medianAnnotation = [sortedAnnotations objectAtIndex:medianIdx];
    treeNode.medianMapPoint = MKMapPointForCoordinate(medianAnnotation.coordinate);

    NSArray *leftAnnotations = [sortedAnnotations subarrayWithRange:NSMakeRange(0, medianIdx)];
    NSArray *rightAnnotations = [sortedAnnotations subarrayWithRange:NSMakeRange(medianIdx, count - medianIdx)];

    NSAssert([leftAnnotations containsObject:medianAnnotation] == NO, nil);
    NSAssert([rightAnnotations containsObject:medianAnnotation], nil);

    MKMapRect leftLeaveMapRect = [self mapRectThatFitsAnnotations:leftAnnotations];
    MKMapRect rightLeaveMapRect = [self mapRectThatFitsAnnotations:rightAnnotations];

    NSAssert(MKMapRectContainsRect(mapRect, leftLeaveMapRect), nil);
    NSAssert(MKMapRectContainsRect(mapRect, rightLeaveMapRect), nil);

    treeNode.left = [self buildTree:leftAnnotations level:(curLevel + 1) mapRect:leftLeaveMapRect];
    treeNode.right = [self buildTree:rightAnnotations level:(curLevel + 1) mapRect:rightLeaveMapRect];

    __block CLLocationCoordinate2D totalCoordinate = CLLocationCoordinate2DMake(0, 0);

    [sortedAnnotations enumerateObjectsUsingBlock:^(CLLocation *annotation, NSUInteger idx, BOOL *stop) {
        totalCoordinate.latitude += annotation.coordinate.latitude;
        totalCoordinate.longitude += annotation.coordinate.longitude;
    }];

    treeNode.totalCoordinate = totalCoordinate;

    return treeNode;
}

- (MKMapRect)mapRectThatFitsAnnotations:(NSArray *)annotations {
    MKMapRect fitRect = MKMapRectNull;

    for (id <MKAnnotation> annotation in annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);

        fitRect = MKMapRectUnion(fitRect, pointRect);
    }
    return fitRect;
}

- (NSArray *)sortedAnnotations:(NSArray *)annotations sortY:(BOOL)sortY {

    return [annotations sortedArrayUsingComparator:^NSComparisonResult(id<MKAnnotation> a1, id<MKAnnotation> a2) {

        MKMapPoint p1 = MKMapPointForCoordinate([a1 coordinate]);
        MKMapPoint p2 = MKMapPointForCoordinate([a2 coordinate]);

        float val1 = (sortY ? p1.y : p1.x);
        float val2 = (sortY ? p2.y : p2.x);

        if(val1 > val2){
            return NSOrderedDescending;
        }
        else if(val1 < val2){
            return NSOrderedAscending;
        }
        else {
            return NSOrderedSame;
        }

    }];
    
}

@end
//        CLLocation *minimalLocation = [sortedAnnotations firstObject];
//        CLLocation *maximalLocation = [sortedAnnotations lastObject];
