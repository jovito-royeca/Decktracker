//
//  CardDetailsViewController.m
//  Decktracker
//
//  Created by Jovit Royeca on 8/6/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "CardDetailsViewController.h"

#import "JJJ/JJJUtil.h"
#import "Artist.h"
#import "CardRarity.h"
#import "Set.h"
#import "UIImage+Scale.h"

@implementation CardDetailsViewController
{
    NSString *_cardPath;
}

@synthesize card = _card;
@synthesize segmentedControl = _segmentedControl;
@synthesize webView = _webView;
@synthesize tableView = _tableView;

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
    
    CGFloat dX = 5;
    CGFloat dY = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height+5;
    CGFloat dWidth = self.view.frame.size.width-10;
    CGFloat dHeight = 30;
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Card", @"Details", @"Pricing",]];
    self.segmentedControl.frame = CGRectMake(dX, dY, dWidth, dHeight);
    [self.segmentedControl addTarget:self
                              action:@selector(switchView:)
                    forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.selectedSegmentIndex = 0;
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = self.card.name;
    [self.view addSubview:self.segmentedControl];
    [self switchView:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) switchView:(id) sender
{
    CGFloat dX = 5;
    CGFloat dY = self.segmentedControl.frame.origin.y + self.segmentedControl.frame.size.height +5;
    CGFloat dWidth = self.view.frame.size.width-10;
    CGFloat dHeight = self.view.frame.size.height - dY - self.tabBarController.tabBar.frame.size.height -5;
    
    [self.imageView removeFromSuperview];
    [self.webView removeFromSuperview];
    [self.tableView removeFromSuperview];
    
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
        {
            _cardPath = [NSString stringWithFormat:@"%@/images/cards/%@/%@.jpg", [[NSBundle mainBundle] bundlePath], self.card.set.code, self.card.imageName];

            if (![[NSFileManager defaultManager] fileExistsAtPath:_cardPath])
            {
                MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:hud];
                hud.delegate = self;
                [hud showWhileExecuting:@selector(downloadCard) onTarget:self withObject:nil animated:NO];
            }
            else
            {
                [self displayCard];
            }
            break;
        }
            
        case 1:
        {
            NSString *path = [[NSBundle mainBundle] bundlePath];
            NSURL *baseURL = [NSURL fileURLWithPath:path];
            
            self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)];
            [self.webView loadHTMLString:[self composeDetails] baseURL:baseURL];
            [self.view addSubview:self.webView];
            break;
        }
        case 2:
        {
            self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight) style:UITableViewStylePlain];
            self.tableView.dataSource = self;
            self.tableView.delegate = self;
            [self.view addSubview:self.tableView];
            break;
        }
    }
}

- (void) downloadCard
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/images/card/%@/", self.card.set.code]];
    _cardPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.jpg", self.card.name]];
    BOOL bFound = YES;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        bFound = NO;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:_cardPath])
    {
        bFound = NO;
    }
    
    if (!bFound)
    {
        NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"http://mtgimage.com/set/%@/%@.jpg", self.card.set.code, self.card.name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
        [JJJUtil downloadResource:url toPath:_cardPath];
    }
}

- (void) displayCard
{
    CGFloat dX = 5;
    CGFloat dY = self.segmentedControl.frame.origin.y + self.segmentedControl.frame.size.height +5;
    CGFloat dWidth = self.view.frame.size.width-10;
    CGFloat dHeight = self.view.frame.size.height - dY - self.tabBarController.tabBar.frame.size.height -5;
    
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:_cardPath];
    CGFloat xDim = (image.size.width * dHeight) / image.size.height;
    image = [image scaleProportionalToSize:CGSizeMake(xDim, dHeight)];
    dX = ((dWidth - xDim) / 2)+5;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(dX, dY, xDim, dHeight)];
    self.imageView.image = image;
    [self.view addSubview:self.imageView];
}

#pragma mark - MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[hud removeFromSuperview];
    [self displayCard];
}

#pragma - mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int rows = 0;
    
	switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 1:
        {
            rows = 3;
            break;
        }
        case 2:
        {
            break;
        }
    }
    
    return rows;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    id <NSFetchedResultsSectionInfo> theSection = [[self.fetchedResultsController sections] objectAtIndex:section];
//
//    return [theSection name];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SearchResultsCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void) configureCell:(UITableViewCell *)cell
           atIndexPath:(NSIndexPath *)indexPath
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 1:
        {
//            switch(indexPath.row)
//            {
//                case 0:
//                {
//                    cell.textLabel.text = @"Legalities";
//                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//                    break;
//                }
//                case 1:
//                {
//                    cell.textLabel.text = @"Language";
//                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//                    break;
//                }
//            }
            break;
        }
        case 2:
        {
            break;
        }
        default:
        {
            break;
        }
    }
}

- (NSString*) composeDetails
{
    NSMutableString *html = [[NSMutableString alloc] init];
    
    NSString *manaPath = [NSString stringWithFormat:@"%@/images/mana", [[NSBundle mainBundle] bundlePath]];
    NSString *setPath = [NSString stringWithFormat:@"%@/images/set", [[NSBundle mainBundle] bundlePath]];
    
    [html appendFormat:@"<html><head><style>td {font-family: Helvetica; font-size: 14px;}</style></head><body>"];
    [html appendFormat:@"<table>"];
    if  (self.card.manaCost)
    {
        NSArray *manas = [[[self.card.manaCost stringByReplacingOccurrencesOfString:@"{" withString:@""] stringByReplacingOccurrencesOfString:@"/" withString:@""] componentsSeparatedByString: @"}"];
        NSMutableString *manaCost = [[NSMutableString alloc] init];
        for (NSString *mana in manas)
        {
            if ([mana isEqualToString:@""])
            {
                continue;
            }
            [manaCost appendFormat:@"<img src=\"%@/%@/24.png\" border=\"0\" />", manaPath, mana];
        }
        [html appendFormat:@"<tr><td><strong>Mana Cost</strong></td><td>%@</td></tr>", manaCost];
    }
    [html appendFormat:@"<tr><td><strong>Converted Mana Cost</strong></td><td><img src=\"%@/%d/24.png\" border=\"0\" /></td></tr>", manaPath, [self.card.convertedManaCost intValue]];
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Type</strong></td></tr>"];
    [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", self.card.type];
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Rarity</strong></td></tr>"];
    [html appendFormat:@"<tr><td colspan=\"2\"><img src=\"%@/%@/%@/24.png\" border=\"0\" /> %@ - %@</td></tr>", setPath, self.card.set.code, [[self.card.rarity.name substringToIndex:1] uppercaseString], self.card.set.name, self.card.rarity.name];
    if (self.card.power || self.card.toughness)
    {
        [html appendFormat:@"<tr><td><strong>Power/Toughness</strong></td><td>%@/%@</td></tr>", self.card.power, self.card.toughness];
    }
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Oracle Text</strong></td></tr>"];
    [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", self.card.text];
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Original Text</v></td></tr>"];
    [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", self.card.originalText];
    if (self.card.flavor)
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><strong>Flavor Text</strong></td></tr>"];
        [html appendFormat:@"<tr><td colspan=\"2\"><i>%@</i></td></tr>", self.card.flavor];
    }
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Artist</strong></td></tr>"];
    [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", self.card.artist.name];
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Sets</strong></td></tr>"];

//    NSArray *arrSets = ];
    for (Set *set in [[self.card.printings allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]])
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><img src=\"%@/%@/%@/24.png\" border=\"0\" /> %@</td></tr>", setPath, set.code, [[self.card.rarity.name substringToIndex:1] uppercaseString], set.name];
    }
    
    [html appendFormat:@"</table>"];
    [html appendFormat:@"</body></html>"];
    return html;
}
@end
