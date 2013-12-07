#import <MapKit/MapKit.h>

typedef struct {
    MKMapPoint point1;
    MKMapPoint point2;
} MKMapLine;

static inline MKMapLine MKMapLineMake(MKMapPoint point1, MKMapPoint point2) {
    MKMapLine line;
    line.point1 = point1;
    line.point2 = point2;
    return line;
}

// http://stackoverflow.com/a/13526485/598057
static inline CLLocationDistance MKMapRectDistanceToMapPoint(MKMapRect mapRect, MKMapPoint point) {
    CLLocationDistance dx = MAX(0, MAX(MKMapRectGetMinX(mapRect) - point.x, point.x - MKMapRectGetMaxX(mapRect)));

    CLLocationDistance dy = MAX(0, MAX(MKMapRectGetMinY(mapRect) - point.y, point.y - MKMapRectGetMaxY(mapRect)));

    return (CLLocationDistance)sqrt(pow(dx, 2) + pow(dy, 2));
}

static inline BOOL MKMapLineIntersectsLine(MKMapLine line1, MKMapLine line2) {
    double q = (line1.point1.y - line2.point1.y) * (line2.point2.x - line2.point1.x) - (line1.point1.x - line2.point1.x) * (line2.point2.y - line2.point1.y);
    double d = (line1.point2.x - line1.point1.x) * (line2.point2.y - line2.point1.y) - (line1.point2.y - line1.point1.y) * (line2.point2.x - line2.point1.x);

    if (d == 0)
    {
        return false;
    }

    float r = q / d;

    q = (line1.point1.y - line2.point1.y) * (line1.point2.x - line1.point1.x) - (line1.point1.x - line2.point1.x) * (line1.point2.y - line1.point1.y);

    float s = q / d;

    if (r < 0 || r > 1 || s < 0 || s > 1) {
        return NO;
    }

    return YES;
}

static inline BOOL MKMapLineIntersectsRect(MKMapLine line, MKMapRect rect)
{
    BOOL intersects = NO;

    MKMapLine CGRectMinYLine = MKMapLineMake(MKMapPointMake(rect.origin.x, rect.origin.y), MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y));

    intersects = MKMapLineIntersectsLine(line, CGRectMinYLine);
    if (intersects) return YES;

    MKMapLine CGRectMaxXLine = MKMapLineMake(MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y), MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height));

    intersects = MKMapLineIntersectsLine(line, CGRectMaxXLine);
    if (intersects) return YES;

    MKMapLine CGRectMaxYLine = MKMapLineMake(
        MKMapPointMake(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height),
        MKMapPointMake(rect.origin.x, rect.origin.y + rect.size.height)
    );

    intersects = MKMapLineIntersectsLine(line, CGRectMaxYLine);
    if (intersects) return YES;


    MKMapLine CGRectMinXLine = MKMapLineMake(
        MKMapPointMake(MKMapRectGetMinY(rect), MKMapRectGetMaxY(rect)),
        MKMapPointMake(MKMapRectGetMinX(rect), MKMapRectGetMinY(rect))
    );

    intersects = MKMapLineIntersectsLine(line, CGRectMinXLine);

    return intersects;
}
