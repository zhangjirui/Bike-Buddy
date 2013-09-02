//
//  MainPageViewController.m
//  Bike Buddy
//
//  Created by AllenCheung on 13-8-26.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//


#import "MainPageViewController.h"
#import "CrumbPath.h"
#import "CrumbPathView.h"
#import "DetailsTableViewController.h"
#import "sys/utsname.h"
#import "MapFlag.h"

#include "Ride.h"
#include "Ride+Create.h"
#include <QuartzCore/QuartzCore.h>

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

#define DISTANCE 1000
#define MINLATITUDE 0.01
#define MINLONGITUDE 0.01
#define AFTERDELAY 10 //结束记录后，等待的最长时间
#define MAXCOUNTTOPAUSE 5 //骑行状态下，获取5次相同的经纬度坐标，即进入智能暂停状态
//self.myAwesomeMenu.startPoint
#define MYAWESOMEMENU_X 28
#define MYAWESOMEMENU_Y 390


@interface MainPageViewController ()


//用于统计时间
@property (nonatomic, retain) NSDate *startRefDate;
@property (nonatomic, retain) NSDate *stopDate; //骑行结束的时间
@property (nonatomic, retain) NSDate *pauseRefDate;  //骑行智能暂停的开始时间（一次骑行，可能有多次智能暂停）

@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic) NSTimeInterval timeInterval; //一次骑行，统计总时间（骑行时间+暂停时间），统计方式：求当前时间和StartRefDate之间的间隔（而不是每执行一次NSTimer就增加1秒）
@property (nonatomic) NSTimeInterval pauseTimeInterval; //一次骑行，统计其中智能暂停的时间

//记录运动轨迹时使用
@property (nonatomic, strong) CrumbPath *crumbs;
@property (nonatomic, strong) CrumbPathView *crumbView;
@property (nonatomic, retain) CLLocation *preLocation;

//记录最快速度
@property (nonatomic) CLLocationSpeed mainPageFastestSpeed;

//截图时使用，记录最高/低 经纬度
@property (nonatomic) CLLocationDegrees HighestLatitude;
@property (nonatomic) CLLocationDegrees LowestLatitude;
@property (nonatomic) CLLocationDegrees HighestLongitude;
@property (nonatomic) CLLocationDegrees LowestLongitude;

//截图
@property (nonatomic, strong) UIImage *mapImage;

//标记animation状态，地图数据加载状态. 0：没有执行；1：开始执行；2：结束执行
@property (nonatomic) NSInteger animationStatus;
@property (nonatomic) NSInteger mapDataLoadStatus;

//@property (nonatomic) BOOL firstTimeGetLocation;

//开始记录后第一次获取到位置坐标；
@property (nonatomic) BOOL firstTimeGetLocationAfterRecord;

//在骑行状态下，统计获取相同经纬度坐标的次数，达到reachPauseStatus，则进入智能暂停状态
@property (nonatomic) NSInteger sameLocationCount;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;



@end


@implementation MainPageViewController

@synthesize locationManager = _locationManager;
@synthesize mapView = _mapView;
@synthesize labelThatShowTimer = _lableThatShowTimer;
@synthesize labelThatShowInstantSpeed = _labelThatShowInstantSpeed;
@synthesize labelThatShowTotalDistance = _labelThatShowTotalDistance;

@synthesize rideDatabase = _rideDatabase;

@synthesize myAwesomeMenu = _myAwesomeMenu;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.locationManager.delegate = self;
    
    [self.locationManager startUpdatingLocation];
    
    self.mapView.delegate = self;
    
    
    //设置当前未开始记录
    self.recordingStatus = 0;
    
    
    //增加awesomemenu, 该view只需增加一次，之后仅针对其更改
    [self initMyAwesomeMenu];
    
    
    self.myAppDelegate = (MainPageAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.myAppDelegate.recordStatus = self.recordingStatus;

}



//存储0：
//存储0.5：add UIMnagedDocument, rideDatabase as this controller's Model
//存储1. Add code to viewWillAppear: to create a default document (for demo purposes)

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //存储：建立 default document
    if (!self.rideDatabase) {
        
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        
        url = [url URLByAppendingPathComponent:@"Default Ride Database"];
        
        //setter will create this for us on disk
        //这里只是建立一个document对象，并未open or create it on the disk
        self.rideDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
        
        // Set our document up for automatic migrations
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        self.rideDatabase.persistentStoreOptions = options;
    }
    
    
    //New1:设置定位精确度，每次载入view之前都设置一次;从本地配置中获取精确度设置
    NSUserDefaults *myUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([myUserDefaults boolForKey:@"settingAccuracy"] == NO) {
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    } else {
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    }
    
    //added 0829
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    
    //[self.mapView removeAnnotations:self.mapView.annotations];
    
}

//存储2：make the rideDatabase's setter starting using it
- (void)setRideDatabase:(UIManagedDocument *)rideDatabase
{
    if (_rideDatabase != rideDatabase) {
        _rideDatabase = rideDatabase;
    }
}

//存储3：Open or create the document here and 并且调用函数向document中存入数据
// get its managedobject context, and start doing stuff
- (void)useDocument
{
    self.recordingStatus = 0; // 停止记录
    [self changeBgAddbuttonColor:self.myAwesomeMenu recordingStatus:self.recordingStatus];
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.rideDatabase.fileURL path]]) {
        //does not exist on disk, so create it
        [self.rideDatabase saveToURL:self.rideDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            
            [self addRideRecordIntoDocument:(self.rideDatabase)];
            
        }];
    } else if (self.rideDatabase.documentState == UIDocumentStateClosed) {
        // exists on disk, but we need to open it
        [self.rideDatabase openWithCompletionHandler:^(BOOL success) {
            
            [self addRideRecordIntoDocument:(self.rideDatabase)];
            
        }];
    } else if (self.rideDatabase.documentState == UIDocumentStateNormal) {
        // already open and ready to use
        [self addRideRecordIntoDocument:(self.rideDatabase)];
    }
}

//存储4：存储骑行记录至database
- (void)addRideRecordIntoDocument:(UIManagedDocument *)document
{
    NSTimeInterval tempInterval = self.timeInterval - self.pauseTimeInterval;
    NSString *tempTotalRideTime = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)tempInterval/3600, ((int)tempInterval%3600)/60, (int)tempInterval%60];
    
    NSString *tempTotalPauseTime = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)self.pauseTimeInterval/3600, ((int)self.pauseTimeInterval%3600)/60, (int)self.pauseTimeInterval%60];
    
    NSString *tempAverageSpeed = [NSString stringWithFormat:@"%.2f km/h", (self.crumbs.totalDistance/1000) / (self.timeInterval/3600)];
    NSString *tempFastestSpeed = [NSString stringWithFormat:@"%.2f km/h", self.mainPageFastestSpeed * 3.6];
    
    //将截图保存到core data中
    self.mapImage = [self imageFromView:self.mapView];
    NSData *mapData = UIImagePNGRepresentation(self.mapImage);
    
    
    [Ride rideWithTotalRideTime:(tempTotalRideTime)
                 totalPauseTime:(tempTotalPauseTime)
                  totalDistance:(self.labelThatShowTotalDistance.text)
                   averageSpeed:(tempAverageSpeed)
                   fastestSpeed:(tempFastestSpeed)
                            map:(mapData)
                      startDate:(self.startRefDate)
                       stopDate:(self.stopDate)
         inManagedObjectContext:(document.managedObjectContext)];
    
    
    //save documents explicitly
    [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success){
        if (!success) {
            //NSLog(@"Failed to save document %@", document.localizedName);
        } else {
            
            //停止spinner 旋转
            [self.spinner stopAnimating];
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            //added 2013-0829-01:08
            [self.crumbs clearCrumbPath];
            
            [self.mapView removeAnnotations:self.mapView.annotations];
            
            [self showNextViewController:@"showDetailsFromMainPage"];
            
        }
    }];
    
}


/*
 *  初始化定位位置，记录轨迹
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //NSLog(@"定位成功！！！");
    
    //NSArray locations 至少含有一个坐标
    CLLocation *newLocation = locations[0];
    
    if (self.recordingStatus == 0) {
        
        CLLocationCoordinate2D centerCoordinate = newLocation.coordinate;
        MKCoordinateRegion mapViewRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, DISTANCE, DISTANCE);
        MKCoordinateRegion mapAdjustedRegion = [self.mapView regionThatFits:mapViewRegion];
        [self.mapView setRegion:mapAdjustedRegion animated:YES];

        //未记录状态，定位成功一次后，关闭定位功能（省电）
        [self.locationManager stopUpdatingLocation];

    }  else if (self.recordingStatus == 1) {   //处于正常骑行状态
        
        if (self.firstTimeGetLocationAfterRecord == YES) {
            // add 0831
            [self createMapFlag:self.mapView coordinate:newLocation.coordinate title:@"Start"];
            self.firstTimeGetLocationAfterRecord = NO;
        }
        
        //显示即时速度
        self.labelThatShowInstantSpeed.text = [NSString stringWithFormat:@"%.2f km/h", (newLocation.speed > 0) ? newLocation.speed*3.6 : 0];
        //获取最快速度
        self.mainPageFastestSpeed = (self.mainPageFastestSpeed > newLocation.speed) ? self.mainPageFastestSpeed : newLocation.speed;
        
        if ( (self.preLocation.coordinate.latitude != newLocation.coordinate.latitude) || (self.preLocation.coordinate.longitude != newLocation.coordinate.longitude) ) {
            
            if ( (!self.crumbs) || (self.crumbs.pointCount == 0)) {
                // first time we're getting a location update
                _crumbs = [[CrumbPath alloc] initWithCenterCoordinate:newLocation.coordinate];
                [self.mapView addOverlay:self.crumbs];
                
                //第一次，zoom map to user location
                CLLocationCoordinate2D centerCoordinate = newLocation.coordinate;
                MKCoordinateRegion mapViewRegion = MKCoordinateRegionMakeWithDistance(centerCoordinate, DISTANCE, DISTANCE);
                MKCoordinateRegion mapAdjustedRegion = [self.mapView regionThatFits:mapViewRegion];
                [self.mapView setRegion:mapAdjustedRegion animated:YES];
                
            }
            
            else {
                MKMapRect updateRect = [self.crumbs addCoordinate:newLocation.coordinate];
                
                if (!MKMapRectIsNull(updateRect)) {
                    MKZoomScale currentZoomScale = (CGFloat)(self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width);
                    
                    CGFloat lineWidth = MKRoadWidthAtZoomScale(currentZoomScale);
                    updateRect = MKMapRectInset(updateRect, -lineWidth, -lineWidth);
                    [self.crumbView setNeedsDisplayInMapRect:updateRect];
                }
            }
            
            //截图时使用，赋值 最高/低 经纬度
            if (newLocation.coordinate.latitude > self.HighestLatitude)
                self.HighestLatitude = newLocation.coordinate.latitude;
            if (newLocation.coordinate.latitude < self.LowestLatitude)
                self.LowestLatitude = newLocation.coordinate.latitude;
            if (newLocation.coordinate.longitude > self.HighestLongitude)
                self.HighestLongitude = newLocation.coordinate.longitude;
            if (newLocation.coordinate.longitude < self.LowestLongitude)
                self.LowestLongitude = newLocation.coordinate.longitude;
            
            //统计总里程
            self.labelThatShowTotalDistance.text = [NSString stringWithFormat:@"%.2f km", self.crumbs.totalDistance / 1000];
        } else { //先后两次坐标 经纬度相同
            self.sameLocationCount ++;
            if (self.sameLocationCount >= MAXCOUNTTOPAUSE) { //进入智能暂停状态
                //NSLog(@"进入智能暂停状态！");
                
                self.recordingStatus = 3;
                [self changeBgAddbuttonColor:self.myAwesomeMenu recordingStatus:self.recordingStatus];
                
                self.pauseRefDate = [NSDate date]; //初始化智能暂停开始时间
            }
        }
        
    } else if (self.recordingStatus == 3) {//智能暂停状态
        //经纬度值发送更新，解除智能暂停状态；
        if ( (self.preLocation.coordinate.latitude != newLocation.coordinate.latitude) || (self.preLocation.coordinate.longitude != newLocation.coordinate.longitude) ) {
            self.sameLocationCount = 0;
            self.recordingStatus = 1;
            [self changeBgAddbuttonColor:self.myAwesomeMenu recordingStatus:self.recordingStatus];
            
            NSDate *nowDate = [NSDate date];
            self.pauseTimeInterval = self.pauseTimeInterval + [nowDate timeIntervalSinceDate:self.pauseRefDate];
        }
    }
    self.preLocation = newLocation;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    _crumbView = [[CrumbPathView alloc] initWithOverlay:overlay];
    return self.crumbView;
}

- (CLLocation *)preLocation
{
    if (!_preLocation) {
        _preLocation = [[CLLocation alloc] init];
    }
    return _preLocation;
}

- (CLLocationManager *)locationManager
{
    if (! _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}


/*
 * 开始or停止记录
 */
- (void)startOrStopRecording {
    
    //开始记录
    if (self.recordingStatus == 0) {
        
        //开始记录后第一次获取到坐标
        self.firstTimeGetLocationAfterRecord = YES;
        
        [self.locationManager startUpdatingLocation];
        self.mapView.userTrackingMode = MKUserTrackingModeFollow;
        
        self.recordingStatus = 1;
        [self changeBgAddbuttonColor:self.myAwesomeMenu recordingStatus:self.recordingStatus];        
        
        //最快速度
        self.mainPageFastestSpeed = 0;
        //截图时使用，初始化 最高/低 经纬度
        self.HighestLatitude = -90;
        self.LowestLatitude = 90;
        self.HighestLongitude = -180;
        self.LowestLongitude = 180;
        
        //初始化animation，mapdataload 状态
        self.animationStatus = 0;
        self.mapDataLoadStatus = 0;
        
        //获取相同经纬度坐标的次数，初始化为0（智能暂停结束后，将该值重置为0）
        self.sameLocationCount = 0;
        
        //每次开始记录，该参数都要置0
        self.pauseTimeInterval = 0;
        
        //self.firstTimeCallTimer = YES;
        self.startRefDate = [NSDate date]; //记录骑行开始的时间
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countTimer:) userInfo:nil repeats:YES];
        
    } else {
        
        //停止记录
        //包括：停止计时器，保存数据至本地
        //暂时将状态记录为2：由记录状态转为停止记录状态
        
        //结束时仍处于智能暂停状态
        //需要统计智能暂停的总时间
        
        [self createMapFlag:self.mapView coordinate:self.locationManager.location.coordinate title:@"Stop"];
        
        [self.locationManager stopUpdatingLocation];
        
        if (self.recordingStatus == 3) {
            NSDate *nowDate = [NSDate date];
            self.pauseTimeInterval = self.pauseTimeInterval + [nowDate timeIntervalSinceDate:self.pauseRefDate];
        }
        
        self.recordingStatus = 2;
        [self.timer invalidate];
        
        self.stopDate = [NSDate date]; //记录结束骑行的时间
        
        //开始执行spinner 旋转
        [self.spinner startAnimating];
        
        //判断是否需要自行 setRegion
        if ((self.HighestLatitude == self.LowestLatitude) && (self.HighestLongitude == self.LowestLongitude)) {
            [self useDocument];
        } else if ((self.HighestLatitude == -90) && (self.LowestLatitude == 90) && (self.HighestLongitude == -180) && (self.LowestLongitude == 180)) {
            [self useDocument];
        } else {
            
            //截图时使用，执行map缩放，以便进行截图
            //注意：有最小范围的限制，要不然，地图精确度达不到。
            CLLocationCoordinate2D centerCoordinate;
            centerCoordinate.latitude = (self.HighestLatitude + self.LowestLatitude) / 2;
            centerCoordinate.longitude = (self.HighestLongitude + self.LowestLongitude) / 2;
            
            CLLocationDegrees myLatitudeDelta = ((self.HighestLatitude - self.LowestLatitude) > MINLATITUDE) ? (self.HighestLatitude - self.LowestLatitude) : MINLATITUDE;
            
            CLLocationDegrees myLongitudeDelta = ((self.HighestLongitude - self.LowestLongitude) > MINLONGITUDE) ? (self.HighestLongitude - self.LowestLongitude) : MINLONGITUDE;
            
            MKCoordinateSpan myCoordinateSpan = MKCoordinateSpanMake(myLatitudeDelta, myLongitudeDelta);
            MKCoordinateRegion myCoordinateRegion = MKCoordinateRegionMake(centerCoordinate, myCoordinateSpan);
            
            [self.mapView setRegion:myCoordinateRegion animated:YES];
            
            [self performSelector:@selector(delaysAfterRecordStopped) withObject:nil afterDelay:AFTERDELAY];
        }
        
    }
}

//功能：若已执行到useDocument，则不做操作；若没有，则强制执行useDocument
- (void)delaysAfterRecordStopped
{
    if (self.recordingStatus != 2) {
        //已执行[self useDocument]
    } else {
        [self useDocument];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    //NSLog(@"将要移动动画！！！");
    if (self.recordingStatus == 2) {
        self.animationStatus = 1;
    }
}

/*
 *  MKMapView animation结束后，会调用此函数
 */

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    //NSLog(@"完成移动动画！！！");
    self.animationStatus = 2;
    
    if (self.recordingStatus == 2) {
        if (self.mapDataLoadStatus == 2) {
            [self useDocument];
        } else if (self.mapDataLoadStatus == 1) {
            //NSLog(@"等待mapDataLoad完成！");
        }
    }
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error
{
    //NSLog(@"加载地图数据失败！");
}
- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView
{
    //NSLog(@"开始加载地图数据！");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if (self.recordingStatus == 2) {
        self.mapDataLoadStatus = 1;
    }
}
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    //NSLog(@"加载地图数据完成！");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    self.mapDataLoadStatus = 2;
    
    if (self.recordingStatus == 2) {
        if (self.animationStatus == 2) {
            [self useDocument];
        } else if (self.animationStatus == 1) {
            //NSLog(@"等待animation完成！");
        }
        
    }
}


/*
 *  截图程序
 */

- (UIImage *)imageFromView:(UIView *)myView
{
    //支持retina高分的关键
    if(UIGraphicsBeginImageContextWithOptions != NULL)
    {
        UIGraphicsBeginImageContextWithOptions(myView.frame.size, NO, 0.0);
    } else {
        UIGraphicsBeginImageContext(myView.frame.size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [myView.layer renderInContext:context];
    UIImage *myImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageWriteToSavedPhotosAlbum(myImage, nil, nil, nil);  //保存到相册中
    
    return myImage;
}


/*
 * 进入下一个viewcontroller
 */
- (void)showNextViewController:(NSString *)identifier
{
    [self performSegueWithIdentifier:identifier sender:self];
}
/*
 * 进入下一个viewcontroller，传递参数给下一个viewcontroller
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showDetailsFromMainPage"]) {
        
        NSTimeInterval tempInterval = self.timeInterval - self.pauseTimeInterval;
        NSString *tempTotalRideTime = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)tempInterval/3600, ((int)tempInterval%3600)/60, (int)tempInterval%60];
        
        [segue.destinationViewController setSegueTotalRideTime:(tempTotalRideTime)];
        
        NSString *tempTotalPauseTime = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)self.pauseTimeInterval/3600, ((int)self.pauseTimeInterval%3600)/60, (int)self.pauseTimeInterval%60];
        
        [segue.destinationViewController setSegueTotalPauseTime:tempTotalPauseTime];
        [segue.destinationViewController setSegueTotalDistance:(self.labelThatShowTotalDistance.text)];
        
        NSString *tempFastestSpeed = [NSString stringWithFormat:@"%.2f km/h", self.mainPageFastestSpeed * 3.6];
        [segue.destinationViewController setSegueFastestSpeed:tempFastestSpeed];
        
        NSString *tempAverageSpeed = [NSString stringWithFormat:@"%.2f km/h", (self.crumbs.totalDistance/1000) / (tempInterval/3600)];
        [segue.destinationViewController setSegueAverageSpeed:tempAverageSpeed];
        
        [segue.destinationViewController setSegueMapImage:self.mapImage];
        [segue.destinationViewController setSegueStartDate:self.startRefDate];
        [segue.destinationViewController setSegueStopDate:self.stopDate];
    }
}

/*
 * 计时，并显示计时器动态走动
 */
- (void)countTimer:(NSTimer *)timer
{
    NSDate *nowDate = [NSDate date];
    self.timeInterval = [nowDate timeIntervalSinceDate:self.startRefDate];
    self.labelThatShowTimer.text = [NSString stringWithFormat:@"%02d:%02d:%02d", (int)self.timeInterval/3600, ((int)self.timeInterval%3600)/60, (int)self.timeInterval%60];
    
    if (self.recordingStatus == 3) {
        
    }
}

/*初始化myMenu*/
- (void)initMyAwesomeMenu
{
    
    UIImage *storyMenuItemImage = [UIImage imageNamed:@"bg-menuitem.png"];
    UIImage *storyMenuItemImagePressed = [UIImage imageNamed:@"bg-menuitem-highlighted.png"];
    
    UIImage *playerPlayImage = [UIImage imageNamed:@"icon-playerPlay.png"];
    UIImage *settingImage = [UIImage imageNamed:@"icon-setting.png"];
    UIImage *historyImage = [UIImage imageNamed:@"icon-history.png"];
    UIImage *positionImage = [UIImage imageNamed:@"icon-position.png"];
    

    
    /* Path-like customization */
    
    AwesomeMenuItem *starMenuItem1 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:playerPlayImage
                                                    highlightedContentImage:nil];
    
    AwesomeMenuItem *starMenuItem2 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:settingImage
                                                    highlightedContentImage:nil];
    
    AwesomeMenuItem *starMenuItem3 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:historyImage
                                                    highlightedContentImage:nil];
    AwesomeMenuItem *starMenuItem4 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                           highlightedImage:storyMenuItemImagePressed
                                                               ContentImage:positionImage
                                                    highlightedContentImage:nil];
    
    
    NSMutableArray  *menus = [NSArray arrayWithObjects:starMenuItem1, starMenuItem2, starMenuItem3, starMenuItem4, nil];
    
    AwesomeMenuItem *startItem = [[AwesomeMenuItem alloc] initWithImage:[UIImage imageNamed:@"bg-addbutton-red.png"]
                                                       highlightedImage:[UIImage imageNamed:@"bg-addbutton-highlighted-red.png"]
                                                           ContentImage:[UIImage imageNamed:@"icon-bike.png"]
                                                highlightedContentImage:[UIImage imageNamed:@"icon-bike-highlighted.png"]];
    
    self.myAwesomeMenu = [[AwesomeMenu alloc] initWithFrame:self.view.bounds startItem:startItem optionMenus:menus];
    self.myAwesomeMenu.delegate = self;
    
	self.myAwesomeMenu.menuWholeAngle = M_PI_2;
	self.myAwesomeMenu.farRadius = 110.0f;
	self.myAwesomeMenu.endRadius = 100.0f;
	self.myAwesomeMenu.nearRadius = 90.0f;
    self.myAwesomeMenu.animationDuration = 0.3f;
    
    if (iPhone5) {
        //NSLog(@"iPhone5");
        self.myAwesomeMenu.startPoint = CGPointMake(MYAWESOMEMENU_X, MYAWESOMEMENU_Y+87);
    } else {
        self.myAwesomeMenu.startPoint = CGPointMake(MYAWESOMEMENU_X, MYAWESOMEMENU_Y);
    }
    
    [self.view addSubview:self.myAwesomeMenu];
}



- (void)changeBgAddbuttonColor:(AwesomeMenu *)menu recordingStatus:(NSInteger)recordingStatus
{
    //0, 停止状态，红灯；1，骑行状态，绿灯；3，智能暂停状态，黄灯
    if (recordingStatus == 0) {
        menu.image = [UIImage imageNamed:@"bg-addbutton-red.png"];
        menu.highlightedImage = [UIImage imageNamed:@"bg-addbutton-highlighted-red.png"];
    } else if (recordingStatus == 1) {
        menu.image = [UIImage imageNamed:@"bg-addbutton-green.png"];
        menu.highlightedImage = [UIImage imageNamed:@"bg-addbutton-highlighted-green.png"];
    } else if (recordingStatus == 3) {
        menu.image = [UIImage imageNamed:@"bg-addbutton-yellow.png"];
        menu.highlightedImage = [UIImage imageNamed:@"bg-addbutton-highlighted-yellow.png"];
    }
}

- (void)awesomeMenu:(AwesomeMenu *)menu didSelectIndex:(NSInteger)idx
{
    //更换图标，开始or结束
    if (idx == 0) {
        
        UIImage *storyMenuItemImage = [UIImage imageNamed:@"bg-menuitem.png"];
        UIImage *storyMenuItemImagePressed = [UIImage imageNamed:@"bg-menuitem-highlighted.png"];
        
        UIImage *settingImage = [UIImage imageNamed:@"icon-setting.png"];
        UIImage *historyImage = [UIImage imageNamed:@"icon-history.png"];
        UIImage *positionImage = [UIImage imageNamed:@"icon-position.png"];
        
        UIImage *playerStartOrStopImage;
        if (self.recordingStatus == 0) {
            playerStartOrStopImage = [UIImage imageNamed:@"icon-playerStop.png"];
        
        } else {
            playerStartOrStopImage = [UIImage imageNamed:@"icon-playerPlay.png"];
            
        }
        
        AwesomeMenuItem *starMenuItem1 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                               highlightedImage:storyMenuItemImagePressed
                                                                   ContentImage:playerStartOrStopImage
                                                        highlightedContentImage:nil];
        
        
        AwesomeMenuItem *starMenuItem2 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                               highlightedImage:storyMenuItemImagePressed
                                                                   ContentImage:settingImage
                                                        highlightedContentImage:nil];
        
        AwesomeMenuItem *starMenuItem3 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                               highlightedImage:storyMenuItemImagePressed
                                                                   ContentImage:historyImage
                                                        highlightedContentImage:nil];
        AwesomeMenuItem *starMenuItem4 = [[AwesomeMenuItem alloc] initWithImage:storyMenuItemImage
                                                               highlightedImage:storyMenuItemImagePressed
                                                                   ContentImage:positionImage
                                                        highlightedContentImage:nil];
        
        
        NSMutableArray *temp = [NSMutableArray arrayWithObjects:starMenuItem1, starMenuItem2, starMenuItem3, starMenuItem4,nil];

        menu.menusArray = temp;
        
        //开始或者结束记录
        [self startOrStopRecording];
        
    } else if (idx == 1) {
        [self showNextViewController:@"showSetting"];
    } else if (idx == 2) {
        //进入历史纪录
        [self showNextViewController:@"showHistory"];
    } else if (idx == 3) {
        self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    }
    
    
    
}
- (void)awesomeMenuDidFinishAnimationClose:(AwesomeMenu *)menu {
    //NSLog(@"Menu was closed!");
}
- (void)awesomeMenuDidFinishAnimationOpen:(AwesomeMenu *)menu {
    //NSLog(@"Menu is open!");
}

- (NSString *)deviceString
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    return deviceString;
    
}

- (void) createMapFlag:(MKMapView *)mapView
            coordinate:(CLLocationCoordinate2D)coordinate
                 title:(NSString *)title
{
    if (mapView != nil) {
        MapFlag *flag = [[MapFlag alloc]initWithCoordinate:coordinate mainTitle:title];
        [mapView addAnnotation:flag];
    }
}


- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MapFlag class]]) {
        MKAnnotationView *newAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"temp"];
        
        CGFloat tempImageHeight = 0;
        
        MapFlag *tempFlag = (MapFlag *)annotation;
        if ([tempFlag.title isEqualToString:@"Start"]) {
            newAnnotationView.image = [UIImage imageNamed:@"flag-start.png"];
        } else if ([tempFlag.title isEqualToString:@"Stop"]) {
            newAnnotationView.image = [UIImage imageNamed:@"flag-stop.png"];
        }
        tempImageHeight = newAnnotationView.image.size.height;
        newAnnotationView.centerOffset = CGPointMake(0, - tempImageHeight / 2);
        return newAnnotationView;
    } else {
        return nil;
    }
}

@end

