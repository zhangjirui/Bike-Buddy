//
//  Ride.h
//  Bike Buddy
//
//  Created by AllenCheung on 13-8-26.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Ride : NSManagedObject

@property (nonatomic, retain) NSString * averageSpeed;
@property (nonatomic, retain) NSString * fastestSpeed;
@property (nonatomic, retain) NSData * map;
@property (nonatomic, retain) NSDate * recordDate;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSDate * stopDate;
@property (nonatomic, retain) NSString * totalDistance;
@property (nonatomic, retain) NSString * totalPauseTime;
@property (nonatomic, retain) NSString * totalRideTime;

@end
