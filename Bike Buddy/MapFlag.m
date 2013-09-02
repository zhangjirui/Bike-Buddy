//
//  MapFlag.m
//  Bike Buddy
//
//  Created by AllenCheung on 13-8-31.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import "MapFlag.h"
#import <AddressBook/AddressBook.h>

@implementation MapFlag
@synthesize title, coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord mainTitle:(NSString *)mainTitle
{
    self = [super init];
    
    if (self) {
        coordinate = coord;
        title = mainTitle;
    }
    
    return self;
}

@end
