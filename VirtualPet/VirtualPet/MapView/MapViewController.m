//
//  ViewController.m
//  VirtualPet
//
//  Created by Ezequiel on 12/1/14.
//  Copyright (c) 2014 Ezequiel. All rights reserved.
//

#import "MapViewController.h"
#import "CustomMapPoint.h"
#import "MyPet.h"

@interface MapViewController ()

@property (strong, nonatomic) Pet* myPet;
@property (strong, nonatomic) IBOutlet MKMapView *myMapView;
@property (strong, nonatomic) NSArray* petArray;
@property (strong, nonatomic) NSMutableArray* annotationsArray;
@property (nonatomic) BOOL isFullMap;

@end

@implementation MapViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andPet: (Pet*) pet
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self)
    {
        self.myPet = pet;
        self.isFullMap = NO;
        self.annotationsArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andPetArray:(NSArray *)petArray
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        self.petArray = petArray;
        self.isFullMap = YES;
        self.annotationsArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"Map"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(NSString*)doReverseGeocoding
{
    __block NSString* address;
    //__weak typeof (self) weakerSelf = self;
    
    CLLocation *c = [[CLLocation alloc] initWithLatitude:self.myPet.location.coordinate.latitude longitude:self.myPet.location.coordinate.longitude];
    CLGeocoder *revGeo = [[CLGeocoder alloc] init];
    [revGeo reverseGeocodeLocation:c
                 completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (!error && [placemarks count] > 0)
         {
             NSString* calle;
             NSString* ciudad;
             NSString* pais;
             
             NSDictionary *dict = [[placemarks objectAtIndex:0] addressDictionary];
             //NSLog(@"street address: %@", [dict objectForKey:@"Street"]);
             calle = [dict objectForKey:@"Street"];
             ciudad = [dict objectForKey:@"City"];
             pais = [dict objectForKey:@"Country"];
             
             address = [NSString stringWithFormat:@"%@ %@ %@", pais, ciudad, calle];
             NSLog(@"Address: %@", address);
             
         }
         else
         {
             NSLog(@"ERROR: %@", error);
         }
     }];
    return address;
}

-  (void)showLines {
    MKPlacemark* sourceCoordinate = [[MKPlacemark alloc] initWithCoordinate:[MyPet sharedInstance].location.coordinate addressDictionary:nil];
    MKMapItem* sourceMapItem = [[MKMapItem alloc] initWithPlacemark:sourceCoordinate];
    [sourceMapItem setName:@"My Pet"];
    
    MKPlacemark* destinationCoordinate = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(self.myPet.locationLat, self.myPet.locationLon) addressDictionary:nil];
    MKMapItem* destinationMapItem = [[MKMapItem alloc] initWithPlacemark:destinationCoordinate];
    [destinationMapItem setName:@"Enemy Pet"];
    
    MKDirectionsRequest* request = [[MKDirectionsRequest alloc] init];
    [request setSource:sourceMapItem];
    [request setDestination:destinationMapItem];
    [request setTransportType:MKDirectionsTransportTypeAny];
    
    MKDirections* directions = [[MKDirections alloc] initWithRequest:request];
    
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse* response, NSError* error){
       
        NSArray* routes = [response routes];
        
        [routes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
           
            MKRoute* route = obj;
            
            MKPolyline* line = [route polyline];
            [self.myMapView addOverlay:line];
        }];
    }];
}

//************************************************************
// Metodos del Delegate
//************************************************************

- (void) mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    MKCoordinateRegion region;
    NSString* address = [self doReverseGeocoding];
    [mapView removeAnnotations:self.annotationsArray];
    
    if(self.isFullMap)
    {
        region.center = CLLocationCoordinate2DMake(0, 0);
        region.span.latitudeDelta = 100;
        region.span.longitudeDelta = 100;
        
        // Seteamos los Pin para cada Pet
        for (Pet* pet in self.petArray)
        {
            CustomMapPoint* annotation = [[CustomMapPoint alloc] initWithPet:pet andAddress:address];
            [self.annotationsArray addObject:annotation];
        }
    }
    else
    {
        region.center = self.myPet.location.coordinate;
        region.span.latitudeDelta = 100;
        region.span.longitudeDelta = 100;
        
        // Seteamos el PIN
        CustomMapPoint* annotation = [[CustomMapPoint alloc] initWithPet:self.myPet andAddress:address];
        [self.annotationsArray addObject:annotation];
        
        CustomMapPoint* myAnnotation = [[CustomMapPoint alloc] initWithPet:[MyPet sharedInstance] andAddress:@"Doesn't matter"];
        [self.annotationsArray addObject:myAnnotation];
        
        [self showLines];
    }
    
    [mapView addAnnotations:self.annotationsArray];
    [mapView setRegion:region animated:YES];
}

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if([annotation isKindOfClass:[CustomMapPoint class]])
    {
        static NSString* identifier = @"CustomMapPoint";
        
        CustomMapPoint* customAnnotation = (CustomMapPoint*)annotation;
        
        MKAnnotationView* annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if(annotationView == nil)
        {
            annotationView = [customAnnotation getAnnotationView];
        }
        else{
            annotationView.annotation = annotation;
        }
        return annotationView;
    }
    else{
         return nil;
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    // create a polylineView using polyline _overlay object
    MKPolylineRenderer *polylineView = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    
    polylineView.strokeColor =  [UIColor redColor];   // applying line-width
    polylineView.lineWidth = 2.0;
    polylineView.alpha = 0.5;
    
    return polylineView;
}


@end
