//
//  LimitedSearchViewController.m
//  Decktracker
//
//  Created by Jovit Royeca on 9/6/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "LimitedSearchViewController.h"
#import "AddCardViewController.h"
#import "DTCard.h"
#import "FileManager.h"
#import "SearchResultsTableViewCell.h"

#ifndef DEBUG
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#endif

@implementation LimitedSearchViewController
{
    NSTimer *_searchTimer;
}

@synthesize deckName = _deckName;
@synthesize searchBar = _searchBar;
@synthesize tblResults = _tblResults;
@synthesize predicate = _predicate;
@synthesize fetchedResultsController = _fetchedResultsController;

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
    {
        return _fetchedResultsController;
    }
    
    NSFetchedResultsController *nsfrc = [[Database sharedInstance] search:self.searchBar.text
                                                            withPredicate:self.predicate
                                                      withSortDescriptors:nil
                                                          withSectionName:nil];
    
    self.fetchedResultsController = nsfrc;
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}

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
    
    CGFloat dX = 0;
    CGFloat dY = 0;
    CGFloat dWidth = self.view.frame.size.width;
    CGFloat dHeight = self.view.frame.size.height;
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.searchBar.delegate = self;
    
    self.tblResults = [[UITableView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)
                                                   style:UITableViewStylePlain];
    self.tblResults.delegate = self;
    self.tblResults.dataSource = self;
    [self.tblResults registerNib:[UINib nibWithNibName:@"SearchResultsTableViewCell" bundle:nil]
          forCellReuseIdentifier:@"Cell"];
    
    // Add a Done button in the keyboard
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self.searchBar
                                                                               action:@selector(resignFirstResponder)];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, dWidth, 44)];
    toolbar.items = [NSArray arrayWithObject:barButton];
    self.searchBar.inputAccessoryView = toolbar;

    self.navigationItem.titleView = self.searchBar;
    [self.view addSubview:self.tblResults];
    [self doSearch];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (_searchTimer.isValid)
    {
        [_searchTimer invalidate];
    }
    _searchTimer = [NSTimer timerWithTimeInterval:2.0
                                           target:self
                                         selector:@selector(doSearch)
                                         userInfo:nil
                                          repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_searchTimer
                              forMode:NSDefaultRunLoopMode];
}

- (void) doSearch
{
    self.fetchedResultsController = nil;
    
    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tblResults reloadData];
}

#pragma mark - UITableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SEARCH_RESULTS_CELL_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = [[self.fetchedResultsController sections] count];
	return count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    
	if (self.fetchedResultsController)
    {
        return [NSString stringWithFormat:@"%tu Results", [sectionInfo numberOfObjects]];
    }
    else
    {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    SearchResultsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[SearchResultsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    DTCard *card = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [cell displayCard:card];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AddCardViewController *view = [[AddCardViewController alloc] init];
    
    view.arrDecks = [[NSMutableArray alloc] initWithArray:@[self.deckName]];
    view.arrCollections = [[NSMutableArray alloc] init];
    for (NSString *file in [[FileManager sharedInstance] listFilesAtPath:@"/Collections"
                                                          fromFileSystem:FileSystemLocal])
    {
        [view.arrCollections addObject:[file stringByDeletingPathExtension]];
    }
    
    view.card = [self.fetchedResultsController objectAtIndexPath:indexPath];
    view.createButtonVisible = NO;
    view.showCardButtonVisible = YES;
    view.segmentedControlIndex = 0;
    [self.navigationController pushViewController:view animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tblResults beginUpdates];
    NSLog(@"%d %s %s", __LINE__, __PRETTY_FUNCTION__, __FUNCTION__);
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    NSLog(@"%d %s %s", __LINE__, __PRETTY_FUNCTION__, __FUNCTION__);
    
    UITableView *tableView = self.tblResults;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            DTCard *card = [self.fetchedResultsController objectAtIndexPath:indexPath];
            SearchResultsTableViewCell *cell = (SearchResultsTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
            [cell displayCard:card];
            break;
        }
        case NSFetchedResultsChangeMove:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id )sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    NSLog(@"%d %s %s", __LINE__, __PRETTY_FUNCTION__, __FUNCTION__);
    
    UITableView *tableView = self.tblResults;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"%d %s %s", __LINE__, __PRETTY_FUNCTION__, __FUNCTION__);
    
    UITableView *tableView = self.tblResults;
    
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [tableView endUpdates];
}

@end