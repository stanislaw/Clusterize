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
     withRespectToCentroids:centroids
     andIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, centroids.count)]];

    [centroids enumerateObjectsUsingBlock:^(Centroid *centroid, NSUInteger idx, BOOL *stop) {
        [centroid calculateLocationBasedOnAccumulatedData];
        NSLog(@"lalala %f", centroid.delta);
    }];

    return result;
}


- (void)doSearchInMapRect:(MKMapRect)mapRect
       mutableAnnotations:(NSMutableArray *)annotations
                  curNode:(KDTreeNode *)curNode
                 curLevel:(NSInteger)level
   withRespectToCentroids:(NSMutableArray *)centroids
               andIndexes:(NSIndexSet *)indexes {

    NSParameterAssert(curNode);

    if (MKMapRectIntersectsRect(mapRect, curNode.mapRect) == NO) {
        return;
    }

    if (curNode.annotation) {
        NSAssert(curNode.numberOfAnnotations == 1, nil);
        
        __block CLLocationDistance minimalSquaredDistance = DBL_MAX;
        __block NSUInteger bestCenterIndex = NSNotFound;

        [centroids enumerateObjectsAtIndexes:indexes options:0 usingBlock:^(Centroid *centroid, NSUInteger idx, BOOL *stop) {
            CLLocationDistance squaredDistanceBeetweenCenterAndPoint = pow(centroid.mapPoint.x - curNode.medianMapPoint.x, 2) + pow(centroid.mapPoint.y - curNode.medianMapPoint.y, 2);

            if (squaredDistanceBeetweenCenterAndPoint < minimalSquaredDistance) {
                minimalSquaredDistance = squaredDistanceBeetweenCenterAndPoint;
                bestCenterIndex = idx;
            }
        }];

        if (bestCenterIndex != NSNotFound) {
            Centroid *bestCentroidFound = [centroids objectAtIndex:bestCenterIndex];

            bestCentroidFound.sumOfMapPoints = MKMapPointMake(bestCentroidFound.sumOfMapPoints.x + curNode.medianMapPoint.x, bestCentroidFound.sumOfMapPoints.y + curNode.medianMapPoint.y);

            bestCentroidFound.numberOfAnnotations++;
        } else {
            abort();
        }

        return;
    }

    if (indexes.count == 0) {
        return;
        //abort();

    }

    else if (indexes.count == 1) {
        Centroid *theOnlyCentroid = [centroids objectAtIndex:indexes.firstIndex];

        theOnlyCentroid.sumOfMapPoints = MKMapPointMake(theOnlyCentroid.sumOfMapPoints.x + curNode.medianMapPoint.x, theOnlyCentroid.sumOfMapPoints.y + curNode.medianMapPoint.y);

        theOnlyCentroid.numberOfAnnotations++;

        return;
    }

    __block CLLocationDistance minimalDistanceBeetweenNodeAndCentroid = DBL_MAX;
    __block NSUInteger candidateCentroidIndex = NSNotFound;


    [centroids enumerateObjectsAtIndexes:indexes options:0 usingBlock:^(Centroid *centroid, NSUInteger centroidIndex, BOOL *stop) {
        CLLocationDistance distanceBeetweenNodeAndCentroid = MKMapRectSquaredDistanceToMapPoint(curNode.mapRect, centroid.mapPoint);

        if (distanceBeetweenNodeAndCentroid == 0) {
            if (minimalDistanceBeetweenNodeAndCentroid == 0) {
                *stop = YES;
                candidateCentroidIndex = NSNotFound;

                return;
            } else {
                minimalDistanceBeetweenNodeAndCentroid = 0;
            }
        }

        // TODO check one center exist!
        else if (minimalDistanceBeetweenNodeAndCentroid > distanceBeetweenNodeAndCentroid) {
            minimalDistanceBeetweenNodeAndCentroid = distanceBeetweenNodeAndCentroid;
            candidateCentroidIndex = centroidIndex;
        }
    }];

    NSMutableIndexSet *indexesForChildrenLeaves = [indexes mutableCopy];

    if (candidateCentroidIndex != NSNotFound) {
        Centroid *candidateCentroid = [centroids objectAtIndex:candidateCentroidIndex];

        __block BOOL candidateCentroidDominatesAllOtherCentroids = YES;

        [centroids enumerateObjectsAtIndexes:indexes options:0 usingBlock:^(Centroid *centroid, NSUInteger centroidIndex, BOOL *stop) {
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

                //*stop = YES; //?
            } else {
                [indexesForChildrenLeaves removeIndex:centroidIndex];
            }
        }];

        if (candidateCentroidDominatesAllOtherCentroids) {
            candidateCentroid.numberOfAnnotations += curNode.numberOfAnnotations;

            candidateCentroid.sumOfMapPoints = MKMapPointMake(
                                                              candidateCentroid.sumOfMapPoints.x + curNode.sumOfMapPoints.x,
                                                              candidateCentroid.sumOfMapPoints.y + curNode.sumOfMapPoints.y
                                                              );

            return;
        }
    }

    [self doSearchInMapRect:mapRect mutableAnnotations:annotations curNode:curNode.left curLevel:(level + 1) withRespectToCentroids:centroids andIndexes:indexesForChildrenLeaves];

    [self doSearchInMapRect:mapRect mutableAnnotations:annotations curNode:curNode.right curLevel:(level + 1) withRespectToCentroids:centroids andIndexes:indexesForChildrenLeaves];
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
        abort();
    }

    KDTreeNode *treeNode = [[KDTreeNode alloc] init];
    treeNode.numberOfAnnotations = count;

    if (count == 1) {
        treeNode.annotation = [annotations firstObject];
        treeNode.medianMapPoint = MKMapPointForCoordinate(treeNode.annotation.coordinate);
        treeNode.mapRect = [self mapRectThatFitsAnnotations:@[ treeNode.annotation ]];

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

    __block MKMapPoint sumOfMapPoints = MKMapPointMake(0, 0);

    [sortedAnnotations enumerateObjectsUsingBlock:^(CLLocation *annotation, NSUInteger idx, BOOL *stop) {
        sumOfMapPoints.x += MKMapPointForCoordinate(annotation.coordinate).x;
        sumOfMapPoints.y += MKMapPointForCoordinate(annotation.coordinate).y;
    }];

    treeNode.sumOfMapPoints = sumOfMapPoints;
    treeNode.numberOfAnnotations = count;

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
