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
        treeNode.numberOfAnnotations = 1;

        return treeNode;
    }

    BOOL sortY = (BOOL)(curLevel % 2);

    NSArray *sortedAnnotations = [self sortedAnnotations:annotations sortY:sortY];

    // Map rect
    MKMapRect treeNodeRect = mapRect;

    MKMapPoint minimalLocationPoint = MKMapPointForCoordinate([[sortedAnnotations firstObject] coordinate]);
    MKMapPoint maximalLocationPoint = MKMapPointForCoordinate([[sortedAnnotations lastObject] coordinate]);

    if (sortY) {
        if (minimalLocationPoint.y > MKMapRectGetMinY(treeNodeRect)) {
            treeNodeRect.origin.y = minimalLocationPoint.y;
            treeNodeRect.size.height = minimalLocationPoint.y + maximalLocationPoint.y + 0.1;
        }
    } else {
        if (minimalLocationPoint.x > MKMapRectGetMinX(treeNodeRect)) {
            treeNodeRect.origin.x = minimalLocationPoint.x;
            treeNodeRect.size.width = minimalLocationPoint.x + maximalLocationPoint.x + 0.1;
        }
    }

    treeNode.mapRect = treeNodeRect;

    // Median map point
    NSInteger medianIdx = [sortedAnnotations count] / 2;
    CLLocation *medianAnnotation = [sortedAnnotations objectAtIndex:medianIdx];
    treeNode.medianMapPoint = MKMapPointForCoordinate(medianAnnotation.coordinate);

    // Leaves
    double amount;
    CGRectEdge edgeToDelimit;

    if (sortY) {
        edgeToDelimit = CGRectMinYEdge;
        amount = treeNode.medianMapPoint.y - treeNode.mapRect.origin.y;
    } else {
        edgeToDelimit = CGRectMinXEdge;
        amount = treeNode.medianMapPoint.x - treeNode.mapRect.origin.x;
    }

    MKMapRect leftLeaveMapRect;
    MKMapRect rightLeaveMapRect;

    MKMapRectDivide(treeNode.mapRect, &leftLeaveMapRect, &rightLeaveMapRect, amount, edgeToDelimit);

    treeNode.left = [self buildTree:[sortedAnnotations subarrayWithRange:NSMakeRange(0, medianIdx)]
                       level:(curLevel + 1) mapRect:mapRect];


    treeNode.right = [self buildTree:[sortedAnnotations subarrayWithRange:NSMakeRange(medianIdx, count - medianIdx)] level:(curLevel + 1) mapRect:mapRect];

    // Total-coordinate
    __block CLLocationCoordinate2D totalCoordinate = CLLocationCoordinate2DMake(0, 0);

    [sortedAnnotations enumerateObjectsUsingBlock:^(CLLocation *annotation, NSUInteger idx, BOOL *stop) {
        totalCoordinate.latitude += annotation.coordinate.latitude;
        totalCoordinate.longitude += annotation.coordinate.longitude;
    }];

    treeNode.totalCoordinate = totalCoordinate;

    return treeNode;
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
