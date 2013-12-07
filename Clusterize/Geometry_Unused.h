#import "Geometry.h"

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

