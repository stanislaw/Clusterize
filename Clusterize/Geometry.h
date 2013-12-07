#import <MapKit/MapKit.h>

static inline CLLocationDistance MKMapRectDistanceToMapPoint(MKMapRect mapRect, MKMapPoint point) {
    double dx = MAX(0, MAX(MKMapRectGetMinX(mapRect) - point.x, point.x - MKMapRectGetMaxX(mapRect)));

    double dy = MAX(0, MAX(MKMapRectGetMinY(mapRect) - point.y, point.y - MKMapRectGetMaxY(mapRect)));

    return sqrt(pow(dx, 2) + pow(dy, 2));
}

static inline BOOL LineIntersectsLine(CGPoint l1p1, CGPoint l1p2, CGPoint l2p1, CGPoint l2p2) {
    CGFloat q = (l1p1.y - l2p1.y) * (l2p2.x - l2p1.x) - (l1p1.x - l2p1.x) * (l2p2.y - l2p1.y);
    CGFloat d = (l1p2.x - l1p1.x) * (l2p2.y - l2p1.y) - (l1p2.y - l1p1.y) * (l2p2.x - l2p1.x);

    if (d == 0)
    {
        return false;
    }

    float r = q / d;

    q = (l1p1.y - l2p1.y) * (l1p2.x - l1p1.x) - (l1p1.x - l2p1.x) * (l1p2.y - l1p1.y);
    float s = q / d;

    if (r < 0 || r > 1 || s < 0 || s > 1) {
        return NO;
    }

    return YES;
}

static inline BOOL LineIntersectsRect(CGPoint p1, CGPoint p2, CGRect r)
{
    return LineIntersectsLine(p1, p2, CGPointMake(r.origin.x, r.origin.y), CGPointMake(r.origin.x + r.size.width, r.origin.y)) ||
    LineIntersectsLine(p1, p2, CGPointMake(r.origin.x + r.size.width, r.origin.y), CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height)) ||
    LineIntersectsLine(p1, p2, CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height), CGPointMake(r.origin.x, r.origin.y + r.size.height)) ||
    LineIntersectsLine(p1, p2, CGPointMake(r.origin.x, r.origin.y + r.size.height), CGPointMake(r.origin.x, r.origin.y)) ||
    (CGRectContainsPoint(r, p1) && CGRectContainsPoint(r, p2));
}