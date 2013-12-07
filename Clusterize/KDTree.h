
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface KDTree : NSObject

@property (nonatomic, readonly) NSSet *annotations;

- (id)initWithAnnotations:(NSArray *)annotations;

- (NSArray *)annotationsInMapRect:(MKMapRect)rect;

@end
