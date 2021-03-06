//
//  SearchInputViewController.m
//  Decktracker
//
//  Created by Jovit Royeca on 8/15/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "FilterInputViewController.h"
#import "Constants.h"
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

@implementation FilterInputViewController
{
    NSIndexPath *_selectedFilterPath;
    int _selectedOperatorIndex;
    NSString *_selectedFilter;
    NSString *_selectedOperator;
    NSArray  *_narrowedFilterOptions;
}

@synthesize filterName = _filterName;
@synthesize filterOptions = _filterOptions;
@synthesize operatorOptions = _operatorOptions;
@synthesize searchBar = _searchBar;
@synthesize tblOperator = _tblOperator;
@synthesize tblFilter = _tblFilter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.operatorOptions = @[@"And", @"Or", @"Not"];
    _selectedFilterPath = [NSIndexPath indexPathForRow:0 inSection:0];
    _selectedOperatorIndex = 0;
    _selectedOperator = [self.operatorOptions firstObject];
    
    CGFloat dX = 0;
    CGFloat dY = 0;
    CGFloat dWidth = self.view.frame.size.width;
    CGFloat dHeight = self.view.frame.size.height;// - self.tabBarController.tabBar.frame.size.height;
    self.tblOperator = [[UITableView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight*0.40)
                                                    style:UITableViewStylePlain];
    self.tblOperator.dataSource = self;
    self.tblOperator.delegate = self;
    [self.view addSubview:self.tblOperator];
    
    if (self.filterOptions)
    {
        id obj = [self.filterOptions firstObject];
        NSString *stringValue;
        
        if ([obj isKindOfClass:[NSManagedObject class]])
        {
            stringValue = [obj performSelector:@selector(name) withObject:nil];
        }
        else if ([obj isKindOfClass:[NSString class]])
        {
            stringValue = obj;
        }
        else if ([obj isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *dict = (NSDictionary*) obj;
            NSArray *arrValues = dict[[[dict allKeys] firstObject]];
            stringValue = [arrValues firstObject];
        }
        _selectedFilter = stringValue;
        
        dY = self.tblOperator.frame.origin.y + self.tblOperator.frame.size.height;
        self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(dX, dY, dWidth, 30)];
        self.searchBar.delegate = self;
        self.searchBar.placeholder = self.filterName;
        self.searchBar.tintColor = [UIColor grayColor];
        // Add a Done button in the keyboard
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self.searchBar
                                                                                   action:@selector(resignFirstResponder)];
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, dWidth, 44)];
        toolbar.items = [NSArray arrayWithObject:barButton];
        self.searchBar.inputAccessoryView = toolbar;
        
        dY = self.searchBar.frame.origin.y + self.searchBar.frame.size.height;
        self.tblFilter = [[UITableView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, (dHeight-self.searchBar.frame.size.height)*0.60)
                                                      style:UITableViewStylePlain];
        self.tblFilter.dataSource = self;
        self.tblFilter.delegate = self;
        
        [self.view addSubview:self.searchBar];
        [self.view addSubview:self.tblFilter];
    }
    else
    {
        dY = self.tblOperator.frame.origin.y + self.tblOperator.frame.size.height;
        self.tblFilter = [[UITableView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight*0.60)
                                                      style:UITableViewStylePlain];
        self.tblFilter.dataSource = self;
        self.tblFilter.delegate = self;
        self.tblFilter.separatorColor = [UIColor clearColor];
        [self.view addSubview:self.tblFilter];
    }
    
    UIBarButtonItem *btnOk = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(btnOkTapped:)];
    UIBarButtonItem *btnCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                           target:self
                                                                           action:@selector(btnCancelTapped:)];
    self.navigationItem.rightBarButtonItem = btnOk;
    self.navigationItem.leftBarButtonItem = btnCancel;
    self.navigationItem.title = self.filterName;
    
#ifndef DEBUG
    // send the screen to Google Analytics
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName
           value:[NSString stringWithFormat:@"Filter Input - %@", self.filterName]];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
#endif
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

-(void) btnOkTapped:(id) sender
{
    NSDictionary *dict = @{@"Filter": self.filterName,
                           @"Value": _selectedFilter,
                           @"Condition": _selectedOperator};
    
    [self.delegate addFilter:dict];
    [self.navigationController popViewControllerAnimated:NO];
}

-(void) btnCancelTapped:(id) sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self searchFilterOptions];
}

- (void) searchFilterOptions
{
    NSString *query = self.searchBar.text;
    NSPredicate *predicate;
    NSMutableArray *arrFilter;
    
    id obj = [self.filterOptions firstObject];
    if ([obj isKindOfClass:[NSManagedObject class]])
    {
        arrFilter = [[NSMutableArray alloc] initWithArray:self.filterOptions];
        
        if (query.length == 1)
        {
            predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[c] %@", @"name", query];
        }
        else if (query.length > 1)
        {
            predicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[c] %@", @"name", query];
        }
    }
    else if ([obj isKindOfClass:[NSDictionary class]])
    {
        arrFilter = [[NSMutableArray alloc] init];
        for (NSDictionary *dict in self.filterOptions)
        {
            NSArray *keywords = dict[[[dict allKeys] firstObject]];
            [arrFilter addObjectsFromArray:keywords];
        }
        
        if (query.length == 1)
        {
            predicate = [NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] %@", query];
        }
        else if (query.length > 1)
        {
            predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[c] %@", query];
        }
    }
    
    if (predicate)
    {
        _narrowedFilterOptions = [arrFilter filteredArrayUsingPredicate:predicate];
        if ([[_narrowedFilterOptions firstObject] isKindOfClass:[NSManagedObject class]])
        {
            _selectedFilter = [[_narrowedFilterOptions firstObject] performSelector:@selector(name) withObject:nil]
            ;
        }
        else if ([[_narrowedFilterOptions firstObject] isKindOfClass:[NSString class]])
        {
            _selectedFilter = [_narrowedFilterOptions firstObject];
        }
    }
    else
    {
        _narrowedFilterOptions = nil;
    }
    
    _selectedFilterPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tblFilter reloadData];
}

#pragma mark - UITableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int sections = 1;
    
    if (tableView == self.tblFilter)
    {
        if (self.filterOptions)
        {
            NSArray *arrFilter = _narrowedFilterOptions ? _narrowedFilterOptions : self.filterOptions;
            
            if ([[arrFilter firstObject] isKindOfClass:[NSDictionary class]])
            {
                sections = (int)arrFilter.count;
            }
        }
    }
    
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.tblFilter)
    {
        if (self.filterOptions)
        {
            NSArray *arrFilter = _narrowedFilterOptions ? _narrowedFilterOptions : self.filterOptions;
            
            if ([[arrFilter firstObject] isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *dict = arrFilter[section];
                return [[dict allKeys] firstObject];
            }
            else
            {
                return nil;
            }
        }
        else
        {
            return nil;
        }
    }
    else if (tableView == self.tblOperator)
    {
        return @"Condition";
    }
    else
    {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tblFilter)
    {
        if (self.filterOptions)
        {
            NSArray *arrFilter = _narrowedFilterOptions ? _narrowedFilterOptions : self.filterOptions;
        
            if ([[arrFilter firstObject] isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *dict = arrFilter[section];
                NSArray *arrValues = dict[[[dict allKeys] firstObject]];
                return arrValues.count;
            }
            else
            {
                return arrFilter.count;
            }
        }
        else
        {
            return 1;
        }
    }
    else if (tableView == self.tblOperator)
    {
        return self.operatorOptions.count;
    }
    else
    {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (tableView == self.tblFilter)
    {
        if (self.filterOptions)
        {
            NSArray *arrFilter = _narrowedFilterOptions ? _narrowedFilterOptions : self.filterOptions;
            
            if ([[self.filterOptions firstObject] isKindOfClass:[DTSet class]])
            {
                DTSet *set = arrFilter[indexPath.row];
                NSString *path = [[FileManager sharedInstance] setPath:set.setId small:YES];
                
                if (path && [[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    UIImage *imgSet = [[UIImage alloc] initWithContentsOfFile:path];
                    // resize the image
                    CGSize itemSize = CGSizeMake(imgSet.size.width/2, imgSet.size.height/2);
                    cell.imageView.image = [JJJUtil imageWithImage:imgSet scaledToSize:itemSize];
                }
                else
                {
                    cell.imageView.image = [UIImage imageNamed:@"blank.png"];
                }
                
                cell.textLabel.text = set.name;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Released: %@ (%d cards)", [JJJUtil formatDate:set.releaseDate withFormat:@"YYYY-MM-dd"], set.numberOfCards];
            }
            else if ([[self.filterOptions firstObject] isKindOfClass:[DTFormat class]])
            {
                DTFormat *format = arrFilter[indexPath.row];
                cell.textLabel.text = format.name;
            }
            else if ([[self.filterOptions firstObject] isKindOfClass:[DTCardRarity class]])
            {
                DTCardRarity *rarity = arrFilter[indexPath.row];
                cell.textLabel.text = rarity.name;
            }
            else if ([[self.filterOptions firstObject] isKindOfClass:[DTCardType class]])
            {
                DTCardType *type = arrFilter[indexPath.row];
                cell.textLabel.text = type.name;
            }
            else if ([[self.filterOptions firstObject] isKindOfClass:[DTCardColor class]])
            {
                DTCardColor *color = arrFilter[indexPath.row];
                NSString *colorInitial;
                if ([color.name isEqualToString:@"Blue"])
                {
                    colorInitial = @"U";
                }
                else if ([color.name isEqualToString:@"Colorless"])
                {
                    colorInitial = @"X";
                }
                else
                {
                    colorInitial = [color.name substringToIndex:1];
                }
                
                NSString *path = [NSString stringWithFormat:@"%@/images/mana/%@/32.png", [[NSBundle mainBundle] bundlePath], colorInitial];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    cell.imageView.image = [UIImage imageNamed:@"blank.png"];
                }
                else
                {
                    UIImage *img = [[UIImage alloc] initWithContentsOfFile:path];
                    CGSize itemSize = CGSizeMake(16, 16);
                    cell.imageView.image = [JJJUtil imageWithImage:img scaledToSize:itemSize];
                }
                
                cell.textLabel.text = color.name;
            }
            else if ([[self.filterOptions firstObject] isKindOfClass:[NSDictionary class]])
            {
                if (_narrowedFilterOptions)
                {
                    cell.textLabel.text = _narrowedFilterOptions[indexPath.row];
                }
                else
                {
                    NSDictionary *dict = arrFilter[indexPath.section];
                    NSArray *arrValues = dict[[[dict allKeys] firstObject]];
                    cell.textLabel.text = arrValues[indexPath.row];
                }
            }
            else if ([[self.filterOptions firstObject] isKindOfClass:[DTArtist class]])
            {
                DTArtist *artist = arrFilter[indexPath.row];
                cell.textLabel.text = artist.name;
            }
            else
            {
                NSString *opt = arrFilter[indexPath.row];
                cell.textLabel.text = opt;
            }
            
            if (_selectedFilterPath && [_selectedFilterPath compare:indexPath] == NSOrderedSame)
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            UITextField *txtField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, self.view.frame.size.width-20, 30)];
            txtField.adjustsFontSizeToFitWidth = YES;
            txtField.borderStyle = UITextBorderStyleRoundedRect;
            txtField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
            txtField.autocapitalizationType = UITextAutocapitalizationTypeNone; // no auto capitalization support
            txtField.placeholder = [NSString stringWithFormat:@"Type %@ here", self.filterName];
            txtField.delegate = self;
            txtField.clearButtonMode = UITextFieldViewModeAlways;
            txtField.tag = 1;
            [txtField addTarget:self
                          action:@selector(textFieldDidChange:)
                forControlEvents:UIControlEventEditingChanged];
            // Add a Done button in the keyboard
            UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                       target:txtField
                                                                                       action:@selector(resignFirstResponder)];
            UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
            toolbar.items = [NSArray arrayWithObject:barButton];
            txtField.inputAccessoryView = toolbar;
            [cell.contentView addSubview:txtField];
        }
    }
    else if (tableView == self.tblOperator)
    {
        cell.textLabel.text = self.operatorOptions[indexPath.row];
        cell.accessoryType = indexPath.row == _selectedOperatorIndex ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tblFilter)
    {
        NSArray *arrFilter = _narrowedFilterOptions ? _narrowedFilterOptions : self.filterOptions;
        NSString *stringValue;

        if ([[self.filterOptions firstObject] isKindOfClass:[NSManagedObject class]])
        {
            id obj = arrFilter[indexPath.row];
            stringValue = [obj performSelector:@selector(name) withObject:nil];
        }
        else if ([[self.filterOptions firstObject] isKindOfClass:[NSString class]])
        {
            stringValue = arrFilter[indexPath.row];
        }
        else if ([[self.filterOptions firstObject] isKindOfClass:[NSDictionary class]])
        {
            if (_narrowedFilterOptions)
            {
                stringValue = _narrowedFilterOptions[indexPath.row];
            }
            else
            {
                NSDictionary *dict = arrFilter[indexPath.section];
                NSArray *arrValues = dict[[[dict allKeys] firstObject]];
                stringValue = arrValues[indexPath.row];
            }
        }
        
        _selectedFilterPath = indexPath;
        _selectedFilter = stringValue;
    }
    else if (tableView == self.tblOperator)
    {
        _selectedOperatorIndex = (int)indexPath.row;
        _selectedOperator = self.operatorOptions[indexPath.row];
    }
    
    if ([self.searchBar canResignFirstResponder])
    {
        [self.searchBar resignFirstResponder];
    }
    
    [tableView reloadData];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    _selectedFilter = textField.text;
    
    if ([textField canBecomeFirstResponder])
    {
        [textField resignFirstResponder];
    }
    return YES;
}

-(void) textFieldDidChange:(id) sender
{
    UITextField *textField = sender;
    
    _selectedFilter = textField.text;
}

@end
