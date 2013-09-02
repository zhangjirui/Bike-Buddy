//
//  Ride+Create.h
//  Bike Buddy
//
//  Created by AllenCheung on 13-8-26.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import "Ride.h"

@interface Ride (Create)

+ (Ride *)rideWithTotalRideTime:(NSString *)totalRideTime
                 totalPauseTime:(NSString *)totalPauseTime
               totalDistance:(NSString *)totalDistance
                averageSpeed:(NSString *)averageSpeed
                fastestSpeed:(NSString *)fastestSpeed
                         map:(NSData *)map
                   startDate:(NSDate *)startDate
                    stopDate:(NSDate *)stopDate
      inManagedObjectContext:(NSManagedObjectContext *)context;

@end
