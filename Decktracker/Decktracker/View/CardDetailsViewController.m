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
#import "CardType.h"
#import "Database.h"
#import "Magic.h"
#import "SimpleSearchViewController.h"
#import "Set.h"
#import "UIImage+Scale.h"

@implementation CardDetailsViewController
{
    NSString *_cardPath;
}

@synthesize card = _card;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize segmentedControl = _segmentedControl;
@synthesize cardImage = cardImage;
@synthesize webView = _webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

-(void) setCard:(Card*) card
{
    _card = card;
    
    _cardPath = [NSString stringWithFormat:@"%@/images/card/%@/%@.jpg", [[NSBundle mainBundle] bundlePath], self.card.set.code, self.card.imageName];
    self.navigationItem.title = self.card.name;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGFloat dX = 10;
    CGFloat dY = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height+10;
    CGFloat dWidth = self.view.frame.size.width-20;
    CGFloat dHeight = 30;
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Card", @"Details", @"Pricing",]];
    self.segmentedControl.frame = CGRectMake(dX, dY, dWidth, dHeight);
    [self.segmentedControl addTarget:self
                              action:@selector(switchView)
                    forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.selectedSegmentIndex = 0;
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.segmentedControl];
    [self switchView];
}
    

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) switchView
{
    CGFloat dX = 0;
    CGFloat dY = self.segmentedControl.frame.origin.y + self.segmentedControl.frame.size.height +10;
    CGFloat dWidth = self.view.frame.size.width;
    CGFloat dHeight = self.view.frame.size.height - dY - self.tabBarController.tabBar.frame.size.height;
    
    [self.cardImage removeFromSuperview];
    [self.webView removeFromSuperview];
    
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
        {
            self.cardImage = [[UIImageView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)];
            self.cardImage.backgroundColor = [UIColor grayColor];
            [self.cardImage setUserInteractionEnabled:YES];
            UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
            UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
            
            // Setting the swipe direction.
            [swipeLeft setDirection:UISwipeGestureRecognizerDirectionLeft];
            [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
            
            // Adding the swipe gesture on image view
            [self.cardImage addGestureRecognizer:swipeLeft];
            [self.cardImage addGestureRecognizer:swipeRight];
            
            [self.view addSubview:self.cardImage];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:_cardPath])
            {
                MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
                [self.view addSubview:hud];
                hud.delegate = self;
                [hud showWhileExecuting:@selector(downloadCard) onTarget:self withObject:nil animated:NO];
            }
            [self displayCard];
            break;
        }
            
        case 1:
        {
            NSString *path = [[NSBundle mainBundle] bundlePath];
            NSURL *baseURL = [NSURL fileURLWithPath:path];
            
            self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)];
            self.webView.delegate = self;
            [self.view addSubview:self.webView];
            [self.webView loadHTMLString:[self composeDetails] baseURL:baseURL];
            break;
        }
        case 2:
        {
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
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    SimpleSearchViewController *parent = [self.navigationController.viewControllers firstObject];
    parent.selectedIndex = [sectionInfo.objects indexOfObject:self.card];
    
    UIImage *image = [UIImage imageWithContentsOfFile:_cardPath];
    
    [self.cardImage setImage:image];
    self.cardImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.cardImage setupImageViewerWithDatasource:self
                                      initialIndex:parent.selectedIndex
                                            onOpen:^{ }
                                           onClose:^{ }];
    self.cardImage.clipsToBounds = YES;
    
    
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)swipe
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    
    NSInteger index = [sectionInfo.objects indexOfObject:self.card];
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionRight)
    {
        index--;
        if (index < 0)
        {
            index = 0;
        }
    }
    else if (swipe.direction == UISwipeGestureRecognizerDirectionLeft)
    {
        index++;
        if (index > sectionInfo.objects.count-1)
        {
            index = sectionInfo.objects.count-1;
        }
    }
    
    Card *card = sectionInfo.objects[index];
    [self setCard:card];
    [self displayCard];
}

- (NSString*) composeDetails
{
    NSMutableString *html = [[NSMutableString alloc] init];
    NSString *setPath = [NSString stringWithFormat:@"%@/images/set", [[NSBundle mainBundle] bundlePath]];
    NSString *manaPath = [NSString stringWithFormat:@"%@/images/mana", [[NSBundle mainBundle] bundlePath]];
    
    [html appendFormat:@"<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"%@/style.css\"></head><body>", [[NSBundle mainBundle] bundlePath]];
    [html appendFormat:@"<table>"];
    
    if (self.card.manaCost)
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><strong>Mana Cost</strong></td></tr>"];
        [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", [self replaceSymbolsInText:self.card.manaCost]];
        [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    }
    
    if (self.card.cmc)
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><strong>Converted Mana Cost</strong></td></tr>"];
        [html appendFormat:@"<tr><td colspan=\"2\"><img src=\"%@/%@/16.png\" border=\"0\" /></td></tr>", manaPath, [self.card.cmc stringValue]];
        [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    }
    
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Type</strong></td></tr>"];
    [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", self.card.type];
    [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    
    if (self.card.power || self.card.toughness)
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><strong>Power/Toughness</strong></td></tr>"];
        [html appendFormat:@"<tr><td colspan=\"2\">%@/%@</td></tr>", self.card.power, self.card.toughness];
        [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    }
    
    if (self.card.loyalty)
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><strong>Loyalty</strong></td></tr>"];
        [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", self.card.loyalty];
        [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    }
    
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Rarity</strong></td></tr>"];
    [html appendFormat:@"<tr><td><img src=\"%@/%@/%@/24.png\" border=\"0\" /></td><td>%@ - %@</td></tr>", setPath, self.card.set.code, [[self.card.rarity.name substringToIndex:1] uppercaseString], self.card.set.name, self.card.rarity.name];
    [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    
    if (self.card.text)
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><strong>Oracle Text</strong></td></tr>"];
        [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", [self replaceSymbolsInText:self.card.text]];
        [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    }
    
    if (self.card.originalText)
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><strong>Original Text</v></td></tr>"];
        [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", [self replaceSymbolsInText:self.card.originalText]];
        [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    }
    
    if (self.card.flavor)
    {
        [html appendFormat:@"<tr><td colspan=\"2\"><strong>Flavor Text</strong></td></tr>"];
        [html appendFormat:@"<tr><td colspan=\"2\"><i>%@</i></td></tr>", self.card.flavor];
        [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    }
    
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Artist</strong></td></tr>"];
    [html appendFormat:@"<tr><td colspan=\"2\">%@</td></tr>", self.card.artist.name];
    [html appendFormat:@"<tr><td colspan=\"2\">&nbsp;</td></tr>"];
    
    [html appendFormat:@"<tr><td colspan=\"2\"><strong>Sets</strong></td></tr>"];
    for (Set *set in [[self.card.printings allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]])
    {
        Card *card = [[Database sharedInstance] findCard:self.card.name inSet:set.code];
        
        NSString *link = [[NSString stringWithFormat:@"card?name=%@&set=%@", card.name, set.code] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [html appendFormat:@"<tr><td><a href=\"%@\"><img src=\"%@/%@/%@/24.png\" border=\"0\" /></a></td><td><a href=\"%@\">%@</a></td></tr>", link, setPath, set.code, [[card.rarity.name substringToIndex:1] uppercaseString], link, set.name];
    }
    
    [html appendFormat:@"</table></body></html>"];
    return html;
}

-(NSString*) replaceSymbolsInText:(NSString*) text
{
    NSMutableArray *arrSymbols = [[NSMutableArray alloc] init];
    
    for (int i=0; i<text.length; i++)
    {
        if ([text characterAtIndex:i] == '{')
        {
            if ([text characterAtIndex:i+2] == '}')
            {
                [arrSymbols addObject:[text substringWithRange:NSMakeRange(i, 3)]];
            }
            else if ([text characterAtIndex:i+4] == '}')
            {
                [arrSymbols addObject:[text substringWithRange:NSMakeRange(i, 5)]];
            }
        }
        
    }
    
    for (NSString *symbol in arrSymbols)
    {
        NSString *center;
        BOOL bFound = NO;
        
        if (symbol.length == 3)
        {
            center = [symbol substringWithRange:NSMakeRange(1, 1)];
        }
        else if (symbol.length == 5)
        {
            center = [symbol substringWithRange:NSMakeRange(1, 3)];
            center = [center stringByReplacingOccurrencesOfString:@"/" withString:@""];
        }
        
        for (NSString *mana in kManaSymbols)
        {
            if ([mana isEqualToString:center])
            {
                text = [text stringByReplacingOccurrencesOfString:symbol withString:[NSString stringWithFormat:@"<img src=\"%@/images/mana/%@/16.png\"/>", [[NSBundle mainBundle] bundlePath], center]];
                bFound = YES;
            }
        }
        
        if (!bFound)
        {
            for (NSString *mana in kOtherSymbols)
            {
                if ([mana isEqualToString:center])
                {
                    text = [text stringByReplacingOccurrencesOfString:symbol withString:[NSString stringWithFormat:@"<img src=\"%@/images/other/%@/16.png\"/>", [[NSBundle mainBundle] bundlePath], center]];
                }
            }
        }
    }
    
    return [text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString * q = [[request URL] query];
    NSArray * pairs = [q componentsSeparatedByString:@"&"];
    NSMutableDictionary * kvPairs = [NSMutableDictionary dictionary];
    for (NSString * pair in pairs)
    {
        NSArray * bits = [pair componentsSeparatedByString:@"="];
        NSString * key = [[bits objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * value = [[bits objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [kvPairs setObject:value forKey:key];
    }
    
    if ([kvPairs objectForKey:@"name"] && [kvPairs objectForKey:@"set"])
    {
    
        Card *card = [[Database sharedInstance] findCard:[kvPairs objectForKey:@"name"]
                                                   inSet:[kvPairs objectForKey:@"set"]];
    
        [self setCard:card];
        self.segmentedControl.selectedSegmentIndex = 0;
        [self switchView];
    }
    
    return YES;
}

#pragma mark - MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[hud removeFromSuperview];
    [self displayCard];
}

#pragma mark -  MHFacebookImageViewerDatasource
- (NSInteger) numberImagesForImageViewer:(MHFacebookImageViewer*) imageViewer
{
    return self.fetchedResultsController.fetchedObjects.count;
}

- (NSURL*) imageURLAtIndex:(NSInteger)index imageViewer:(MHFacebookImageViewer*) imageViewer
{
    Card *card = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        NSString *cardPath = [NSString stringWithFormat:@"%@/images/card/%@/%@.jpg", [[NSBundle mainBundle] bundlePath], card.set.code, card.imageName];
    [self setCard:card];
    [self displayCard];
    
    // pre-download or fetch remotely depending on settings ??
//    return [NSURL URLWithString:[[NSString stringWithFormat:@"http://mtgimage.com/set/%@/%@.hq.jpg", card.set.code, card.name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    // just return bundled image for now
    return [NSURL fileURLWithPath:cardPath];
}

- (UIImage*) imageDefaultAtIndex:(NSInteger)index imageViewer:(MHFacebookImageViewer*) imageViewer
{
    Card *card = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    NSString *cardPath = [NSString stringWithFormat:@"%@/images/card/%@/%@.jpg", [[NSBundle mainBundle] bundlePath], card.set.code, card.imageName];
    [self setCard:card];
    [self displayCard];
    return [UIImage imageWithContentsOfFile:cardPath];
}

@end
