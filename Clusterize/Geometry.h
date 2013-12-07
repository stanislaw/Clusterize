#import <MapKit/MapKit.h>
#import <EchoLogger/EchoLogger.h>

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

static inline BOOL MKMapLineSegmentContainsPoint(MKMapLine line, MKMapPoint point) {
    NSLog(@"Line: %@", NSStringFromMKMapLine(line));

    double slope, intercept;

    double left, top, right, bottom; // Bounding Box For Line Segment

    double dx = line.point2.x - line.point1.x;

    bottom = MIN(line.point1.y, line.point2.y);
    top = MAX(line.point1.y, line.point2.y);

    if (dx == 0) {
        return (point.x == line.point1.x) && (point.y < top) && (point.y > bottom);
    }

    left = MIN(line.point1.x, line.point2.x);
    right = MAX(line.point2.x, line.point1.x);

    double dy = line.point2.y - line.point1.y;

    slope = dy / dx;

    // y = mx + c
    // intercept c = y - mx
    intercept = line.point1.y - slope * line.point1.x; // which is same as y2 - slope * x2

    if ((slope * point.x + intercept) > (point.y - 0.01) && (slope * point.x + intercept) < (point.y + 0.01)) {
        if(point.x >= left && point.x <= right && point.y <= bottom && point.y <= top) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - ???

static inline BOOL MKMapLineSecmentIntersectsLineSegment2(MKMapLine line1, MKMapLine line2) {
    NSLog(@"First line: %@", NSStringFromMKMapLine(line1));
    NSLog(@"Second line: %@", NSStringFromMKMapLine(line2));

    double q = (line1.point1.y - line2.point1.y) * (line2.point2.x - line2.point1.x) - (line1.point1.x - line2.point1.x) * (line2.point2.y - line2.point1.y);
    double d = (line1.point2.x - line1.point1.x) * (line2.point2.y - line2.point1.y) - (line1.point2.y - line1.point1.y) * (line2.point2.x - line2.point1.x);

    if (d == 0) {
        return NO;
    }

    double r = q / d;

    q = (line1.point1.y - line2.point1.y) * (line1.point2.x - line1.point1.x) - (line1.point1.x - line2.point1.x) * (line1.point2.y - line1.point1.y);

    double s = q / d;

    if (r < 0 || r > 1 || s < 0 || s > 1) {
        return NO;
    }

    return YES;
}

// http://stackoverflow.com/a/1968345/598057
static inline BOOL MKMapLineSecmentIntersectsLineSegment(MKMapLine line1, MKMapLine line2, double *i_x, double *i_y) {
    double s1_x = line1.point2.x - line1.point1.x,
           s1_y = line1.point2.y - line1.point1.y,
           s2_x = line2.point2.x - line2.point1.x,
           s2_y = line2.point2.y - line2.point1.y;

    double s = (-s1_y * (line1.point1.x - line2.point1.x) + s1_x * (line1.point1.y - line2.point1.y)) / (-s2_x * s1_y + s1_x * s2_y);
    double t = ( s2_x * (line1.point1.y - line2.point1.y) - s2_y * (line1.point1.x - line2.point1.x)) / (-s2_x * s1_y + s1_x * s2_y);

    if (s >= 0 && s <= 1 && t >= 0 && t <= 1) {
        if (i_x != NULL) {
            *i_x = line1.point1.x + (t * s1_x);
        }

        if (i_y != NULL) {
            *i_y = line1.point1.y + (t * s1_y);
        }

        return YES;
    }

    return NO;
}

#pragma mark - WIP

static inline BOOL MKMapLineIntersectsLineSegment(MKMapLine line, MKMapLine lineSegment, MKMapPoint *intersectionPoint) {
    double lineA = line.point2.y - line.point1.y;
    double lineB = line.point1.x - line.point2.x;
    double lineC = lineA * line.point1.x + lineB * line.point1.y;

    double lineSegmentA = lineSegment.point2.y - lineSegment.point1.y;
    double lineSegmentB = lineSegment.point1.x - lineSegment.point2.x;
    double lineSegmentC = lineSegmentA * lineSegment.point1.x + lineSegmentB * lineSegment.point1.y;

    double det = lineA * lineSegmentB - lineSegmentA * lineB;

    double x, y;

    //LSLog(@"line, lineSegment: %@ %@", NSStringFromMKMapLine(line), NSStringFromMKMapLine(lineSegment));

    if (det == 0) {
        return NO;
    } else {
        x = (lineSegmentB * lineC - lineB * lineSegmentC) / det;
        y = (lineA * lineSegmentC - lineSegmentA * lineC) / det;

        //LSLog(@"intersection: %f %f", x, y);

        double bottom = MIN(lineSegment.point1.y, lineSegment.point2.y);
        double top = MAX(lineSegment.point1.y, lineSegment.point2.y);

        double left = MIN(lineSegment.point1.x, lineSegment.point2.x);
        double right = MAX(lineSegment.point2.x, lineSegment.point1.x);

        if (intersectionPoint != NULL) {
            *intersectionPoint = MKMapPointMake(x, y);
        }

        return (left <= x) && (x <= right) && (bottom <= y) && (y <= top);
    }



    return det != 0;
}

static inline BOOL MKMapLineIntersectsRect(MKMapLine line, MKMapRect rect)
{
    BOOL intersects = MKMapRectContainsPoint(rect, line.point1) || MKMapRectContainsPoint(rect, line.point2);
    if (intersects) return YES;

    MKMapLine CGRectMinYLine = MKMapLineMake(MKMapPointMake(rect.origin.x, rect.origin.y), MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y));

    intersects = MKMapLineIntersectsLineSegment(line, CGRectMinYLine, NULL);
    if (intersects) return YES;

    MKMapLine CGRectMaxXLine = MKMapLineMake(MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y), MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height));

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
