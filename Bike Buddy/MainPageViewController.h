//
//  MainPageViewController.h
//  Bike Buddy
//
//  Created by AllenCheung on 13-8-26.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "AwesomeMenu.h"
#import "MainPageAppDelegate.h"


@interface MainPageViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, AwesomeMenuDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, retain) CLLocationManager *locationManager;

@property (weak, nonatomic) IBOutlet UILabel *labelThatShowTimer;
@property (weak, nonatomic) IBOutlet UILabel *labelThatShowInstantSpeed;
@property (weak, nonatomic) IBOutlet UILabel *labelThatShowTotalDistance;

@property (nonatomic, strong) UIManagedDocument *rideDatabase; // 骑行记录的存储

@property (nonatomic, retain) AwesomeMenu *myAwesomeMenu;

@property (nonatomic, strong) MainPageAppDelegate *myAppDelegate;

//骑行状态：1，正在记录；0，没有记录； 2,从记录中转为结束记录的中间状态; 3,智能暂停状态；
@property (nonatomic) NSInteger recordingStatus; 
@end
