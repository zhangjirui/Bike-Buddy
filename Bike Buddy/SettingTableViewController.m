//
//  SettingTableViewController.m
//  Bike Buddy
//
//  Created by AllenCheung on 13-8-28.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import "SettingTableViewController.h"

@interface SettingTableViewController ()

@end

@implementation SettingTableViewController

@synthesize settingAccuracy = _settingAccuracy;

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"%d", [self.settingAccuracy isOn]);
    
    NSUserDefaults *myUserDefaults = [NSUserDefaults standardUserDefaults];
    if ([myUserDefaults objectForKey:@"settingAccuracy"] == nil) {
        
    } else if ([myUserDefaults boolForKey:@"settingAccuracy"] == NO) {
        self.settingAccuracy.on = NO;
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *myUserDefaults = [NSUserDefaults standardUserDefaults];
    [myUserDefaults setBool:[self.settingAccuracy isOn] forKey:@"settingAccuracy"];
    [myUserDefaults synchronize];
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *myCell = [tableView cellForRowAtIndexPath:indexPath];
    if ([myCell.textLabel.text isEqualToString:@"图片来源"]) {
        NSString *pictureSource = @"https://www.iconfinder.com";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:pictureSource]];
    } else if ([myCell.textLabel.text isEqualToString:@"源代码"]) {
        NSString *pictureSource = @"https://github.com/allencheung";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:pictureSource]];
    } else if ([myCell.textLabel.text isEqualToString:@"开发者微博"]) {
        NSString *pictureSource = @"http://weibo.com/zjrzsu";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:pictureSource]];
    } else if ([myCell.textLabel.text isEqualToString:@"高德地图Legal"]) {
        NSString *pictureSource = @"http://gspa21.ls.apple.com/html/attribution.cn.html";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:pictureSource]];
    }
}


@end
