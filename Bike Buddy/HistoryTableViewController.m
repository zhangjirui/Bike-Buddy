//
//  HistoryTableViewController.m
//  Bike
//
//  Created by AllenCheung on 13-8-12.
//  Copyright (c) 2013年 Allen Cheung. All rights reserved.
//

#import "HistoryTableViewController.h"
#import "Ride.h"
#import "DetailsTableViewController.h"


@interface HistoryTableViewController ()



@end

@implementation HistoryTableViewController

@synthesize rideDatabase = _rideDatabase;


// I change my model, I've got to reload the data, this is a  wholosale change.
- (void)setHistoryRecords:(NSMutableArray *)historyRecords
{
    _historyRecords = historyRecords;
    [self.tableView reloadData];
}

 
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //获取存储1：建立 default document
    if (!self.rideDatabase) {
        
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        
        url = [url URLByAppendingPathComponent:@"Default Ride Database"];
        
        self.rideDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        self.rideDatabase.persistentStoreOptions = options;
    }
}

//获取存储2：make the rideDatabase's setter starting using it
- (void)setRideDatabase:(UIManagedDocument *)rideDatabase
{
    if (_rideDatabase != rideDatabase) {
        _rideDatabase = rideDatabase;
        [self useDocument];
    }
}

//获取存储3：Open or create the document here and 并且调用函数向document中存入数据
- (void)useDocument
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.rideDatabase.fileURL path]]) {
        //does not exist on disk, so create it
    } else if (self.rideDatabase.documentState == UIDocumentStateClosed) {
        // exists on disk, but we need to open it
        [self.rideDatabase openWithCompletionHandler:^(BOOL success) {
            
            self.historyRecords = [self getRideRecordsFromDatabase:(self.rideDatabase)];
            
        }];
    } else if (self.rideDatabase.documentState == UIDocumentStateNormal) {
        // already open and ready to use
        self.historyRecords = [self getRideRecordsFromDatabase:(self.rideDatabase)];
    }
}

//获取存储4：将存储记录复制到 NSMutableArray historyRecords

- (NSMutableArray *)getRideRecordsFromDatabase:(UIManagedDocument *)document
{
    //查询数据库，获取所有记录
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Ride"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"recordDate" ascending:NO]];

    request.predicate = nil;
    
    NSError *error = nil;
    NSArray *matches = [document.managedObjectContext executeFetchRequest:request error:&error];
    
    if (!matches) {
        NSLog(@"record failed!");
        matches = nil;
    }
    NSMutableArray *mutableMatches = [matches mutableCopy];
    return mutableMatches;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"showDetailsFromHistory"]) {
                Ride *ride = self.historyRecords[indexPath.row];
                [segue.destinationViewController setSegueStartDate:ride.startDate];
                [segue.destinationViewController setSegueStopDate:ride.stopDate];
                [segue.destinationViewController setSegueTotalRideTime:ride.totalRideTime];
                [segue.destinationViewController setSegueTotalPauseTime:ride.totalPauseTime];
                [segue.destinationViewController setSegueTotalDistance:ride.totalDistance];
                [segue.destinationViewController setSegueAverageSpeed:ride.averageSpeed];
                [segue.destinationViewController setSegueFastestSpeed:ride.fastestSpeed];
                
                UIImage *myImage = [UIImage imageWithData:ride.map];
                [segue.destinationViewController setSegueMapImage:myImage];
            }
        }
    }
}


/*
 *  Delete the selected object.
 *  Update the table view.
 *  Save the changes.
 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the managed object at the given index path.
        NSManagedObject *eventToDelete = [self.historyRecords objectAtIndex:indexPath.row];
        [self.rideDatabase.managedObjectContext deleteObject:eventToDelete];
        
        if ([_historyRecords isKindOfClass:[NSMutableArray class]]) {
            NSLog(@"dd");
        }
        // Update the array and table view.
        [self.historyRecords removeObjectAtIndex:indexPath.row];

        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
        // Commit the change.
        NSError *error = nil;
        if (![self.rideDatabase.managedObjectContext save:&error]) {
            // Handle the error.
        } else {
            NSLog(@"删除成功！！！");
        }
    }
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.historyRecords count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Ride Record";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Ride *ride = self.historyRecords[indexPath.row];
    
    NSDateFormatter *myDateFormatter = [[NSDateFormatter alloc] init];
    [myDateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [myDateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    cell.textLabel.text = [myDateFormatter stringFromDate:ride.startDate];
    NSString *myDetail = @"里程:";
    myDetail = [myDetail stringByAppendingString:ride.totalDistance];
    myDetail = [myDetail stringByAppendingString:@" 耗时:"];
    myDetail = [myDetail stringByAppendingString:ride.totalRideTime];
    cell.detailTextLabel.text = myDetail;
    

    
    return cell;
}

@end
