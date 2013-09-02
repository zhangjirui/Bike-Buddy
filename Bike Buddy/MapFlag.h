//
//  MapFlag.h
//  Bike Buddy
//
//  Created by AllenCheung on 13-8-31.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapFlag : NSObject <MKAnnotation>
{
    NSString *title;
    CLLocationCoordinate2D coordinate;
}



- (id) initWithCoordinate:(CLLocationCoordinate2D)coord
                           mainTitle:(NSString *)mainTitle;

@end
