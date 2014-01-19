#import <MapKit/MapKit.h>

typedef struct {
    MKMapPoint point1;
    MKMapPoint point2;
} MKMapLine;

static inline NSString * NSStringFromMKMapLine(MKMapLine line) {
    NSString *string = [NSString stringWithFormat:@"(MKMapLine){%f, %f, %f, %f}", line.point1.x, line.point1.y, line.point2.x, line.point2.y];

    return string;
}

static inline MKMapLine MKMapLineMake(MKMapPoint point1, MKMapPoint point2) {
    MKMapLine line;
    line.point1 = point1;
    line.point2 = point2;
    return line;
}

#pragma mark - Good

// http://stackoverflow.com/a/13526485/598057
static inline CLLocationDistance MKMapRectDistanceToMapPoint(MKMapRect mapRect, MKMapPoint point) {
    CLLocationDistance dx = MAX(0, MAX(MKMapRectGetMinX(mapRect) - point.x, point.x - MKMapRectGetMaxX(mapRect)));

    CLLocationDistance dy = MAX(0, MAX(MKMapRectGetMinY(mapRect) - point.y, point.y - MKMapRectGetMaxY(mapRect)));

    return (CLLocationDistance)sqrt(pow(dx, 2) + pow(dy, 2));
}

static inline CLLocationDistance MKMapRectSquaredDistanceToMapPoint(MKMapRect mapRect, MKMapPoint point) {
    CLLocationDistance dx = MAX(0, MAX(MKMapRectGetMinX(mapRect) - point.x, point.x - MKMapRectGetMaxX(mapRect)));

    CLLocationDistance dy = MAX(0, MAX(MKMapRectGetMinY(mapRect) - point.y, point.y - MKMapRectGetMaxY(mapRect)));

    return (CLLocationDistance)(pow(dx, 2) + pow(dy, 2));
}


// http://community.topcoder.com/tc?module=Static&d1=tutorials&d2=geometry2
static inline BOOL MKMapLineIntersectsLineSegment(MKMapLine line, MKMapLine lineSegment, MKMapPoint *intersectionPoint) {
    double lineA = line.point2.y - line.point1.y;
    double lineB = line.point1.x - line.point2.x;
    double lineC = lineA * line.point1.x + lineB * line.point1.y;

    double lineSegmentA = lineSegment.point2.y - lineSegment.point1.y;
    double lineSegmentB = lineSegment.point1.x - lineSegment.point2.x;
    double lineSegmentC = lineSegmentA * lineSegment.point1.x + lineSegmentB * lineSegment.point1.y;

    double det = lineA * lineSegmentB - lineSegmentA * lineB;

    if (det == 0) {
        return NO;
    } else {
        double bottom, top;

        if (lineSegment.point1.y < lineSegment.point2.y) {
            bottom = lineSegment.point1.y;
            top = lineSegment.point2.y;
        } else {
            bottom = lineSegment.point2.y;
            top = lineSegment.point1.y;
        }

        double left, right;
        if (lineSegment.point1.x < lineSegment.point2.x) {
            left = lineSegment.point1.x;
            right = lineSegment.point2.x;
        } else {
            left = lineSegment.point2.x;
            right = lineSegment.point1.x;
        }

        double x = (lineSegmentB * lineC - lineB * lineSegmentC) / det;
        double y = (lineA * lineSegmentC - lineSegmentA * lineC) / det;

        if (intersectionPoint != NULL) {
            *intersectionPoint = MKMapPointMake(x, y);
        }

        return (left <= x) && (x <= right) && (bottom <= y) && (y <= top);
    }

    return det != 0;
}

static inline BOOL MKMapLineIntersectsRect(MKMapLine line, MKMapRect rect) {
    BOOL intersects = MKMapRectContainsPoint(rect, line.point1) || MKMapRectContainsPoint(rect, line.point2);
    if (intersects) return YES;


    MKMapLine CGRectMinYLine = MKMapLineMake(
        MKMapPointMake(MKMapRectGetMinX(rect), MKMapRectGetMinY(rect)),
        MKMapPointMake(MKMapRectGetMaxX(rect), MKMapRectGetMinY(rect))
    );

    intersects = MKMapLineIntersectsLineSegment(line, CGRectMinYLine, NULL);
    if (intersects) return YES;


    MKMapLine CGRectMaxXLine = MKMapLineMake(
        MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y),
        MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height)
    );

    intersects = MKMapLineIntersectsLineSegment(line, CGRectMaxXLine, NULL);
    if (intersects) return YES;


    MKMapLine CGRectMaxYLine = MKMapLineMake(
        MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height),
        MKMapPointMake(rect.origin.x, rect.origin.y + rect.size.height)
    );

    intersects = MKMapLineIntersectsLineSegment(line, CGRectMaxYLine, NULL);
    if (intersects) return YES;


    MKMapLine CGRectMinXLine = MKMapLineMake(
        MKMapPointMake(MKMapRectGetMinY(rect), MKMapRectGetMaxY(rect)),
        MKMapPointMake(MKMapRectGetMinX(rect), MKMapRectGetMinY(rect))
    );

    intersects = MKMapLineIntersectsLineSegment(line, CGRectMinXLine, NULL);
    return intersects;
}
