//
//  Ride+Create.m
//  Bike Buddy
//
//  Created by AllenCheung on 13-8-26.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import "Ride+Create.h"

@implementation Ride (Create)

+ (Ride *)rideWithTotalRideTime:(NSString *)totalRideTime
                 totalPauseTime:(NSString *)totalPauseTime
              totalDistance:(NSString *)totalDistance
               averageSpeed:(NSString *)averageSpeed
               fastestSpeed:(NSString *)fastestSpeed
                        map:(NSData *)map
                  startDate:(NSDate *)startDate
                   stopDate:(NSDate *)stopDate
     inManagedObjectContext:(NSManagedObjectContext *)context
{
    Ride *ride = nil;
    
    //这里确定recordTime
    NSDate *recordDate = [NSDate date];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Ride"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"recordDate" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"recordDate = %@", recordDate];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if (!matches) {
        NSLog(@"record failed!");
    } else if (![matches count]) {  //none found, create a new Ride
        ride = [NSEntityDescription insertNewObjectForEntityForName:@"Ride"
                                             inManagedObjectContext:context];
        ride.recordDate = recordDate;
        ride.totalRideTime = totalRideTime;
        ride.totalPauseTime = totalPauseTime;
        ride.totalDistance = totalDistance;
        ride.averageSpeed = averageSpeed;
        ride.fastestSpeed = fastestSpeed;
        ride.map = map;
        ride.startDate = startDate;
        ride.stopDate = stopDate;
    
    } else if ([matches count] == 1){
        //ride = [matches lastObject];
        NSLog(@"record failed!");
    }
    
    return ride;
    
}

@end
