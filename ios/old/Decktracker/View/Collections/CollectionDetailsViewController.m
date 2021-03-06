//
//  CollectionDetailsViewController.m
//  Decktracker
//
//  Created by Jovit Royeca on 9/9/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "CollectionDetailsViewController.h"
#import "JJJ/JJJ.h"
#import "AddCardViewController.h"
#import "Database.h"
#import "FileManager.h"
#import "SearchResultsTableViewCell.h"

#ifndef DEBUG
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#endif

@implementation CollectionDetailsViewController
{
    NSArray *_arrSections;
    NSMutableArray *_arrRegulars;
    NSMutableArray *_arrFoils;
}

@synthesize dictCollection = _dictCollection;
@synthesize tblCards = _tblCards;
@synthesize bottomToolbar = _bottomToolbar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _arrSections = @[@"Regular", @"Foiled"];
    
    CGFloat dX = 0;
    CGFloat dY = 0;
    CGFloat dWidth = self.view.frame.size.width;
    CGFloat dHeight = self.view.frame.size.height - 44;
    
    self.tblCards = [[UITableView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)
                                                 style:UITableViewStyleGrouped];
    self.tblCards.delegate = self;
    self.tblCards.dataSource = self;
    [self.tblCards registerNib:[UINib nibWithNibName:@"SearchResultsTableViewCell" bundle:nil]
        forCellReuseIdentifier:@"Cell1"];
    
    dHeight = 44;
    dY = self.view.frame.size.height - dHeight;
    dWidth = self.view.frame.size.width;
    self.bottomToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)];
    
    [self.view addSubview:self.tblCards];
    [self.view addSubview:self.bottomToolbar];

#ifndef DEBUG
    // send the screen to Google Analytics
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:@"Collection Details"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
#endif
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self loadCollection];
    [self.tblCards reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) loadCollection
{
    NSDictionary *deck = [[FileManager sharedInstance] loadFileAtPath:[NSString stringWithFormat:@"/Collections/%@.json", _dictCollection[@"name"]]];
    
    NSSortDescriptor *sorter1 = [[NSSortDescriptor alloc] initWithKey:@"card.name"  ascending:YES];
    NSSortDescriptor *sorter2 = [[NSSortDescriptor alloc] initWithKey:@"card.set.releaseDate"  ascending:NO];
    NSArray *sorters = @[sorter1, sorter2];
    
    _arrRegulars = [[NSMutableArray alloc] init];
    _arrFoils = [[NSMutableArray alloc] init];
    int totalCards = 0;
    
    for (NSDictionary *dict in deck[@"regular"])
    {
        DTCard *card = [[Database sharedInstance] findCard:dict[@"card"] inSet:dict[@"set"]];
        
        [_arrRegulars addObject:@{@"card": card,
                                  @"qty" : dict[@"qty"]}];
        totalCards += [dict[@"qty"] intValue];
    }
    
    for (NSDictionary *dict in deck[@"foiled"])
    {
        DTCard *card = [[Database sharedInstance] findCard:dict[@"card"] inSet:dict[@"set"]];
        
        [_arrFoils addObject:@{@"card": card,
                               @"qty" : dict[@"qty"]}];
    }
    
    _arrRegulars = [[NSMutableArray alloc] initWithArray:[_arrRegulars sortedArrayUsingDescriptors:sorters]];
    _arrFoils = [[NSMutableArray alloc] initWithArray:[_arrFoils sortedArrayUsingDescriptors:sorters]];
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@ / %d Cards", deck[@"name"], totalCards];
}

-(UITableViewCell*) createSearchResultsTableCell:(NSDictionary*) dict withBadge:(int) badge
{
    SearchResultsTableViewCell *cell = [self.tblCards dequeueReusableCellWithIdentifier:@"Cell1"];
    if (cell == nil)
    {
        cell = [[SearchResultsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:@"Cell1"];
    }
    
    [cell displayCard:dict[@"card"]];
    [cell addBadge:badge];
    return cell;
}

-(BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

#pragma mark - UITableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SEARCH_RESULTS_CELL_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    int count = 0;
    
    switch (section)
    {
        case 0:
        {
            for (NSDictionary *dict in _arrRegulars)
            {
                count += [dict[@"qty"] intValue];
            }
            break;
        }
        case 1:
        {
            for (NSDictionary *dict in _arrFoils)
            {
                count += [dict[@"qty"] intValue];
            }
            break;
        }
    }
    
    return [NSString stringWithFormat:@"%@: %tu", _arrSections[section], count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
    {
        case 0:
        {
            return _arrRegulars.count;
        }
        case 1:
        {
            return _arrFoils.count;
        }
        default:
        {
            return 1;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;

    switch (indexPath.section)
    {
        case 0:
        {
            NSDictionary *dictRegulars = _arrRegulars[indexPath.row];
            int badge = [dictRegulars[@"qty"] intValue];
            cell = [self createSearchResultsTableCell:dictRegulars withBadge:badge];
            break;
        }
        case 1:
        {
            NSDictionary *dictFoils = _arrFoils[indexPath.row];
            int badge = [dictFoils[@"qty"] intValue];
            cell = [self createSearchResultsTableCell:dictFoils withBadge:badge];
            break;
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DTCard *card;
    
    switch (indexPath.section)
    {
        case 0:
        {
            card = _arrRegulars[indexPath.row][@"card"];
            break;
        }
        case 1:
        {
            card = _arrFoils[indexPath.row][@"card"];
            break;
        }
    }
    
    if (card)
    {
        UIViewController *view;
        
        NSDictionary *dict = [[Database sharedInstance] inAppSettingsForSet:card.set];
        if (dict)
        {
            InAppPurchaseViewController *view2 = [[InAppPurchaseViewController alloc] init];
            
            view2.productID = dict[@"In-App Product ID"];
            view2.delegate = self;
            view2.productDetails = @{@"name" : dict[@"In-App Display Name"],
                                     @"description": dict[@"In-App Description"]};
            view = view2;
        }
        else
        {
            AddCardViewController *view2 = [[AddCardViewController alloc] init];
            
            view2.arrDecks = [[NSMutableArray alloc] init];
            for (NSString *file in [[FileManager sharedInstance] listFilesAtPath:@"/Decks"
                                                                  fromFileSystem:FileSystemLocal])
            {
                [view2.arrDecks addObject:[file stringByDeletingPathExtension]];
            }
            
            view2.arrCollections = [[NSMutableArray alloc] initWithArray:@[self.dictCollection[@"name"]]];
            [view2 setCard:card];
            view2.createButtonVisible = NO;
            view2.showCardButtonVisible = YES;
            view2.segmentedControlIndex = 1;
            view = view2;
        }
        
        if (view)
        {
            [self.navigationController pushViewController:view animated:YES];
        }
    }
}

#pragma mark - InAppPurchaseViewControllerDelegate
-(void) productPurchaseSucceeded:(NSString*) productID
{
    [[Database sharedInstance] loadInAppSets];
    [self.tblCards reloadData];
}

@end
