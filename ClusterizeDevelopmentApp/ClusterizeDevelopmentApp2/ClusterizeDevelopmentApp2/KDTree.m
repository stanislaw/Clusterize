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
