//
//  DetailsTableViewController.h
//  Bike
//
//  Created by AllenCheung on 13-8-15.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailsTableViewController : UITableViewController

@property (strong, nonatomic) NSString *segueTotalRideTime;
@property (strong, nonatomic) NSString *segueTotalDistance;
@property (strong, nonatomic) NSString *segueFastestSpeed;
@property (strong, nonatomic) NSString *segueAverageSpeed;
@property (strong, nonatomic) UIImage *segueMapImage;

@property (strong, nonatomic) NSDate *segueStartDate;
@property (strong, nonatomic) NSDate *segueStopDate;
@property (strong, nonatomic) NSString *segueTotalPauseTime;

@property (strong, nonatomic) IBOutlet UILabel *totalRideTimeDetail;

@property (strong, nonatomic) IBOutlet UILabel *totalDistanceDetail;

@property (strong, nonatomic) IBOutlet UILabel *averageSpeedDetail;
@property (strong, nonatomic) IBOutlet UILabel *fastestSpeedDetail;

@property (strong, nonatomic) IBOutlet UIImageView *imageViewDetail;

@property (strong, nonatomic) IBOutlet UILabel *startDateDetail;
@property (strong, nonatomic) IBOutlet UILabel *stopDateDetail;
@property (strong, nonatomic) IBOutlet UILabel *totalPauseTimeDetail;

@end
