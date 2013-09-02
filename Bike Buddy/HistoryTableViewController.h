//
//  HistoryTableViewController.h
//  Bike
//
//  Created by AllenCheung on 13-8-12.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface HistoryTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *historyRecords;  // model for this MVC

@property (nonatomic, strong) UIManagedDocument *rideDatabase;

@end
