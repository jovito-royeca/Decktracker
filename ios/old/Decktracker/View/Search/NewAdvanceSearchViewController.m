//
//  NewAdvanceSearchViewController.m
//  Decktracker
//
//  Created by Jovit Royeca on 8/18/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "NewAdvanceSearchViewController.h"
#import "AdvanceSearchResultsViewController.h"
#import "Database.h"
#import "DTArtist.h"
#import "DTCardColor.h"
#import "DTCardRarity.h"
#import "DTCardType.h"
#import "DTFormat.h"
#import "DTSet.h"
#import "FileManager.h"

#ifndef DEBUG
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#endif

@implementation NewAdvanceSearchViewController
{
    UIBarButtonItem *_btnPlay;
    UIView *_viewSegmented;
    NSArray *_arrFilters;
    NSArray *_arrSorters;
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    NSFetchedResultsController *nsfrc = [[Database sharedInstance] advanceSearch:self.dictCurrentQuery
                                                                      withSorter:self.dictCurrentSorter];
    
    self.fetchedResultsController = nsfrc;
    return _fetchedResultsController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
        self.dictCurrentQuery = [[NSMutableDictionary alloc] init];
        self.dictCurrentSorter = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _arrFilters = @[@"Name",
                    @"Set",
                    @"Format",
                    @"Rarity",
                    @"Type",
                    @"Subtype",
                    @"Color",
                    @"Keyword",
                    @"Text",
                    @"Flavor Text",
                    @"Artist",
                    @"Will Be Reprinted?"];
    
    _arrSorters = @[@"Name"];
    
    CGFloat dX = 0;
    CGFloat dY = 0;
    CGFloat dWidth = self.view.frame.size.width;
    CGFloat dHeight = self.view.frame.size.height;//-self.tabBarController.tabBar.frame.size.height;
    
    self.tblView = [[UITableView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)
                                                style:UITableViewStylePlain];
    self.tblView.delegate = self;
    self.tblView.dataSource = self;
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Filter", @"Search Criteria"]];
    self.segmentedControl.frame = CGRectMake(dX+10, dY+7, dWidth-20, 30);
    [self.segmentedControl addTarget:self
                              action:@selector(segmentedControlChangedValue:)
                    forControlEvents:UIControlEventValueChanged];
    
    dHeight = 44;
    _viewSegmented = [[UIView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)];
    _viewSegmented.backgroundColor = [UIColor whiteColor];
    [_viewSegmented addSubview:self.segmentedControl];
    
    [self.view addSubview:self.tblView];
    
    _btnPlay = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                             target:self
                                                             action:@selector(btnPlayTapped:)];
    UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                               target:self
                                                                               action:@selector(btnCancelTapped:)];
    self.navigationItem.leftBarButtonItem = btnCancel;

    if (self.mode == EditModeNew)
    {
        self.navigationItem.title = @"New Advance Search";
    }
    
#ifndef DEBUG
    // send the screen to Google Analytics
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:self.navigationItem.title];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
#endif
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.dictCurrentQuery.count > 0)
    {
        self.segmentedControl.selectedSegmentIndex = 1;
    }
    else
    {
        self.segmentedControl.selectedSegmentIndex = 0;
    }
    
    [self.segmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) hidesBottomBarWhenPushed
{
    return YES;
}

-(void) btnPlayTapped:(id) sender
{
    if (self.dictCurrentQuery.count == 0)
    {
        [JJJUtil alertWithTitle:@"Error" andMessage:@"Select at least one filter"];
    }
    else
    {
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:hud];
        hud.delegate = self;
        [hud showWhileExecuting:@selector(doSearch) onTarget:self withObject:nil animated:NO];

#ifndef DEBUG
        // send to Google Analytics
        id tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Advance Search"
                                                              action:self.mode == EditModeEdit ? @"Edit" : @"New"
                                                               label:@"Run"
                                                               value:nil] build]];
#endif
    }
}

-(void) btnCancelTapped:(id) sender
{
    [self.navigationController popViewControllerAnimated:NO];

#ifndef DEBUG
    // send to Google Analytics
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Advance Search"
                                                          action:self.mode == EditModeEdit ? @"Edit" : @"New"
                                                           label:@"Cancel"
                                                           value:nil] build]];
#endif
}

-(void) doSearch
{
    self.fetchedResultsController = nil;
    
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

-(void) segmentedControlChangedValue:(id) sender
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
        {
            self.tblView.editing = NO;
            self.navigationItem.rightBarButtonItem = nil;
            break;
        }
        case 1:
        {
            self.tblView.editing = YES;
            self.navigationItem.rightBarButtonItem = _btnPlay;
            break;
        }
    }
    
    [self.tblView reloadData];
}

-(void) showSegment:(int) index
{
    self.segmentedControl.selectedSegmentIndex = index;
    [self.segmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark - UITableView
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.segmentedControl.selectedSegmentIndex == 1)
    {
        if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.section > 0)
        {
            NSString *key = [self.dictCurrentQuery allKeys][indexPath.section-1];
            NSMutableArray *rows = self.dictCurrentQuery[key];
            [rows removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            
            if (rows.count == 0)
            {
                [self.dictCurrentQuery removeObjectForKey:key];
            }
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath

{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 1:
        {
            return YES;
        }
        default:
        {
            return NO;
        }
    }
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 1:
        {
            return UITableViewCellEditingStyleDelete;
        }
        default:
        {
            return UITableViewCellEditingStyleNone;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
        {
            if (section == 0)
            {
                return _viewSegmented.frame.size.height;
            }
        }
        case 1:
        {
            if (section == 0)
            {
                return _viewSegmented.frame.size.height;
            }
        }
    }
    
    return UITableViewAutomaticDimension;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
        {
            if (section == 0)
            {
                return _viewSegmented;
            }
        }
        case 1:
        {
            if (section == 0)
            {
                return _viewSegmented;
            }
            else
            {
                return nil;
            }
        }
    }

    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 1:
        {
            if (section > 0)
            {
                return [self.dictCurrentQuery allKeys][section-1];
            }
        }
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 1:
        {
            return [self.dictCurrentQuery allKeys].count +1;
        }
        default:
        {
            return 1;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
        {
//            if (section == 0)
//            {
//                return 0;
//            }
//            else
//            {
                return _arrFilters.count;
//            }
        }
        case 1:
        {
            if (section == 0)
            {
                return 0;
            }
            else
            {
                NSString *key = [self.dictCurrentQuery allKeys][section-1];
                NSMutableArray *rows = self.dictCurrentQuery[key];
            
                return rows.count;
            }
        }
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
        {
//            if (indexPath.section > 0)
            {
                cell.textLabel.text = _arrFilters[indexPath.row];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
        }
        case 1:
        {
            if (indexPath.section > 0)
            {
                NSString *key = [self.dictCurrentQuery allKeys][indexPath.section-1];
                NSMutableArray *rows = self.dictCurrentQuery[key];
                NSDictionary *dict = rows[indexPath.row];
                NSString *stringValue;
                id value = [[dict allValues] firstObject];
                
                if ([value isKindOfClass:[NSManagedObject class]])
                {
                    stringValue = [value performSelector:@selector(name) withObject:nil];
                }
                else if ([value isKindOfClass:[NSString class]])
                {
                    stringValue = value;
                }
                
                cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ = '%@'", [[dict allKeys] firstObject], key, stringValue];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *arrFilterOptions = [[NSMutableArray alloc] init];

    if ([_arrFilters[indexPath.row] isEqualToString:@"Set"])
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"magicCardsInfoCode != %@ AND NOT (code IN %@)", @"", [[Database sharedInstance] inAppSetCodes]];
        
        for (DTSet *set in [[DTSet objectsWithPredicate:predicate] sortedResultsUsingProperty:@"name" ascending:YES])
        {
            [arrFilterOptions addObject:set];
        }
    }
    else if ([_arrFilters[indexPath.row] isEqualToString:@"Format"])
    {
        for (DTFormat *format in [[DTFormat allObjects] sortedResultsUsingProperty:@"name" ascending:YES])
        {
            [arrFilterOptions addObject:format];
        }
    }
    else if ([_arrFilters[indexPath.row] isEqualToString:@"Rarity"])
    {
        for (DTCardRarity *rarity in [DTCardRarity allObjects])
        {
            [arrFilterOptions addObject:rarity];
        }
    }
    else if ([_arrFilters[indexPath.row] isEqualToString:@"Type"])
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name IN %@", CARD_TYPES];
        
        for (DTCardType *cardType in [[DTCardType objectsWithPredicate:predicate] sortedResultsUsingProperty:@"name" ascending:YES])
        {
            [arrFilterOptions addObject:cardType];
        }
    }
    else if ([_arrFilters[indexPath.row] isEqualToString:@"Subtype"])
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (name IN %@)", CARD_TYPES];
        
        for (DTCardType *cardType in [[DTCardType objectsWithPredicate:predicate] sortedResultsUsingProperty:@"name" ascending:YES])
        {
            [arrFilterOptions addObject:cardType];
        }
    }
    else if ([_arrFilters[indexPath.row] isEqualToString:@"Color"])
    {
        for (DTCardColor *cardColor in [[DTCardColor allObjects] sortedResultsUsingProperty:@"name" ascending:YES])
        {
            [arrFilterOptions addObject:cardColor];
        }
    }
    else if ([_arrFilters[indexPath.row] isEqualToString:@"Keyword"])
    {
        [arrFilterOptions addObjectsFromArray:[[FileManager sharedInstance] loadKeywords]];
    }
    else if ([_arrFilters[indexPath.row] isEqualToString:@"Artist"])
    {
        for (DTArtist *artist in [[DTArtist allObjects] sortedResultsUsingProperty:@"name" ascending:YES])
        {
            [arrFilterOptions addObject:artist];
        }
    }
    else if ([_arrFilters[indexPath.row] isEqualToString:@"Will Be Reprinted?"])
    {
        [arrFilterOptions addObjectsFromArray:@[@"Yes", @"No"]];
    }
    
    FilterInputViewController *view = [[FilterInputViewController alloc] init];
    view.delegate = self;
    view.filterOptions = arrFilterOptions;
    view.filterName = _arrFilters[indexPath.row];
    [self.navigationController pushViewController:view animated:YES];
}

#pragma mark - FilterInputViewControllerDelegate
-(void) addFilter:(NSDictionary*) filter
{
    NSMutableArray *arrRows = self.dictCurrentQuery[filter[@"Filter"]];
    
    if (!arrRows)
    {
        arrRows = [[NSMutableArray alloc] init];
        [self.dictCurrentQuery setObject:arrRows forKey:filter[@"Filter"]];
    }
    [arrRows addObject:@{filter[@"Condition"] : filter[@"Value"]}];
}

#pragma mark - MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[hud removeFromSuperview];
    
    AdvanceSearchResultsViewController *view = [[AdvanceSearchResultsViewController alloc] init];
    
    view.fetchedResultsController = self.fetchedResultsController;
    view.fetchedResultsController.delegate = view;
    view.queryToSave = self.dictCurrentQuery;
    view.sorterToSave = self.dictCurrentSorter;
    view.mode = EditModeNew;
    view.navigationItem.title = self.navigationItem.title;
    [self.navigationController pushViewController:view animated:NO];
}

@end
