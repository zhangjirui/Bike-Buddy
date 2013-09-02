//
//  DetailsTableViewController.m
//  Bike
//
//  Created by AllenCheung on 13-8-15.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import "DetailsTableViewController.h"

@interface DetailsTableViewController ()

@end

@implementation DetailsTableViewController

@synthesize segueTotalRideTime = _segueTotalRideTime;
@synthesize segueTotalDistance = _segueTotalDistance;
@synthesize segueFastestSpeed = _segueFastestSpeed;
@synthesize segueAverageSpeed = _segueAverageSpeed;
@synthesize segueMapImage = _segueMapImage;


@synthesize totalRideTimeDetail = _totalRideTimeDetail;
@synthesize totalDistanceDetail = _totalDistanceDetail;
@synthesize averageSpeedDetail = _averageSpeedDetail;
@synthesize fastestSpeedDetail = _fastestSpeedDetail;
@synthesize imageViewDetail = _imageViewDetail;
@synthesize startDateDetail = _startDateDetail;
@synthesize stopDateDetail = _stopDateDetail;


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.totalRideTimeDetail.text = self.segueTotalRideTime;
    self.totalPauseTimeDetail.text = self.segueTotalPauseTime;
    self.totalDistanceDetail.text = self.segueTotalDistance;
    self.averageSpeedDetail.text = self.segueAverageSpeed;
    self.fastestSpeedDetail.text = self.segueFastestSpeed;
    self.imageViewDetail.image = self.segueMapImage;
    
    NSDateFormatter *myDateFormatter = [[NSDateFormatter alloc] init];
    [myDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [myDateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    self.startDateDetail.text = [myDateFormatter stringFromDate:self.segueStartDate];
    self.stopDateDetail.text = [myDateFormatter stringFromDate:self.segueStopDate];
}

- (IBAction)shareAction:(id)sender {
    NSString *rideDistance = @";  骑行里程";
    NSString *rideTime = @";  骑行时长";
    NSString *pauseTime = @";  暂停时长";

    NSString *averageSpeed = @";  平均速度";
    NSString *fastestSpeed = @";  最快速度";
    NSString *startTime = @"  开始时间";
    NSString *stopTime = @";  结束时间";
    
    NSArray *activityItems = [[NSArray alloc] initWithObjects:@"#骑行信息汇总#",
                              [startTime stringByAppendingString : self.startDateDetail.text],
                              [stopTime stringByAppendingString : self.stopDateDetail.text],
                              [rideDistance stringByAppendingString : self.totalDistanceDetail.text],
                              [rideTime stringByAppendingString : self.totalRideTimeDetail.text],
                              [pauseTime stringByAppendingString : self.totalPauseTimeDetail.text],
                              [averageSpeed stringByAppendingString : self.averageSpeedDetail.text],
                              [fastestSpeed stringByAppendingString : self.fastestSpeedDetail.text],
                              self.imageViewDetail.image, nil];
    
    //初始化一个UIActivityViewController
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:Nil];
    
    NSArray *activityTypes = [[NSArray alloc] initWithObjects:@"UIActivityTypeAssignToContact", nil];
    activityVC.excludedActivityTypes = activityTypes;
    
    activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    };
    
    [self presentViewController:activityVC animated:YES completion:^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }];
}


@end
