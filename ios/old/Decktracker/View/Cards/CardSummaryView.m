//
//  SearchResultsTableViewCell.m
//  Decktracker
//
//  Created by Jovit Royeca on 8/24/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "CardSummaryView.h"
#import "DTSet.h"
#import "FileManager.h"

#import "EDStarRating.h"

@implementation CardSummaryView
{
    UIFont *_pre8thEditionFont;
    UIFont *_8thEditionFont;
    EDStarRating *_ratingControl;
    NSString *_currentCropPath;
}

@synthesize lblRank = _lblRank;
@synthesize imgCrop = _imgCrop;
@synthesize lblCardName = _lblCardName;
@synthesize lblDetail = _lblDetail;
@synthesize viewManaCost = _viewManaCost;
@synthesize imgSet = _imgSet;
@synthesize lblBadge = _lblBadge;
@synthesize viewRating = _viewRating;
@synthesize lblLowPrice = _lblLowPrice;
@synthesize lblMedianPrice = _lblMedianPrice;
@synthesize lblHighPrice = _lblHighPrice;
@synthesize lblFoilPrice = _lblFoilPrice;
@synthesize imgType = _imgType;

- (void)awakeFromNib
{
    // Initialization code
    self.imgCrop.layer.cornerRadius = 10.0;
    self.imgCrop.layer.masksToBounds = YES;
    
    _pre8thEditionFont = [UIFont fontWithName:@"Magic:the Gathering" size:20];
    _8thEditionFont = [UIFont fontWithName:@"Matrix-Bold" size:18];
    
    _ratingControl = [[EDStarRating alloc] initWithFrame:self.viewRating.frame];
    _ratingControl.userInteractionEnabled = NO;
    _ratingControl.starImage = [UIImage imageNamed:@"star.png"];
    _ratingControl.starHighlightedImage = [UIImage imageNamed:@"starhighlighted.png"];
    _ratingControl.maxRating = 5;
    _ratingControl.backgroundColor = [UIColor clearColor];
    _ratingControl.displayMode=EDStarRatingDisplayHalf;
    
    self.lblCardName.adjustsFontSizeToFitWidth = YES;
    self.lblDetail.adjustsFontSizeToFitWidth = YES;
    self.lblSet.adjustsFontSizeToFitWidth = YES;
    self.lblLowPrice.adjustsFontSizeToFitWidth = YES;
    self.lblMedianPrice.adjustsFontSizeToFitWidth = YES;
    self.lblHighPrice.adjustsFontSizeToFitWidth = YES;
    self.lblFoilPrice.adjustsFontSizeToFitWidth = YES;
    
    [self.viewRating removeFromSuperview];
    [self addSubview:_ratingControl];
}

-(id) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        
    }
    
    return self;
}

-(void) displayCard:(NSString*) cardId
{
    self.cardId = cardId;

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCardDownloadCompleted
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadCropImage:)
                                                 name:kCardDownloadCompleted
                                               object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kParseSyncDone
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(parseSyncDone:)
                                                 name:kParseSyncDone
                                               object:nil];

    DTCard *card = [DTCard objectForPrimaryKey:cardId];
    
    NSMutableString *type = [[NSMutableString alloc] initWithFormat:@"%@", card.type];
    
    if (card.power.length > 0 || card.toughness.length > 0)
    {
        [type appendFormat:@" (%@/%@)", card.power, card.toughness];
    }
    else
    {
        DTCardType *planeswalkerType = [[DTCardType objectsWithPredicate:[NSPredicate predicateWithFormat:@"name = %@", @"Planeswalker"]] firstObject];
        
        for (DTCardType *cardType in card.types)
        {
            if (cardType == planeswalkerType)
            {
                [type appendFormat:@" (Loyalty: %d)", card.loyalty];
                break;
            }
        }
    }
    
    if (card.modern)
    {
        self.lblCardName.font = _8thEditionFont;
    }
    else
    {
        self.lblCardName.font = _pre8thEditionFont;
    }
    
    self.lblCardName.text = [NSString stringWithFormat:@" %@", card.name];
    self.lblDetail.text = type;
    self.lblSet.text = [NSString stringWithFormat:@"%@ (%@)", card.set.name, card.rarity.name];
    _ratingControl.rating = (float)card.rating;
    [[Database sharedInstance] fetchCardRating:cardId];
    
    // crop image
    _currentCropPath = [[FileManager sharedInstance] cropPath:cardId];
    self.imgCrop.image = [[UIImage alloc] initWithContentsOfFile:_currentCropPath];
    [[FileManager sharedInstance] downloadCardImage:cardId immediately:NO];
    
    // type image
    NSString *path = [[FileManager sharedInstance] cardTypePath:cardId];
    if (path)
    {
        UIImage *typeImage = [[UIImage alloc] initWithContentsOfFile:path];
        // resize the image
        CGSize itemSize = CGSizeMake(typeImage.size.width/2, typeImage.size.height/2);
        self.imgType.image = [JJJUtil imageWithImage:typeImage scaledToSize:itemSize];
    }
    else
    {
        self.imgType.image = nil;
    }
    
    // set image
    NSDictionary *dict = [[Database sharedInstance] inAppSettingsForSet:card.set.setId];
    if (dict)
    {
        self.imgSet.image = [UIImage imageNamed:@"locked.png"];
    }
    else
    {
        path = [[FileManager sharedInstance] cardSetPath:cardId];
        if (path)
        {
            UIImage *setImage = [[UIImage alloc] initWithContentsOfFile:path];
            self.imgSet.image = [JJJUtil imageWithImage:setImage scaledToSize:CGSizeMake(setImage.size.width/2, setImage.size.height/2)];
        }
        else
        {
            self.imgSet.image = nil;
        }
    }
    
    NSArray *arrManaImages = [[FileManager sharedInstance] manaImagesForCard:cardId];
    
    // remove first
    for (UIView *view in [self.viewManaCost subviews])
    {
        [view removeFromSuperview];
    }
    [self.lblCardName removeFromSuperview];
    [self.viewManaCost removeFromSuperview];
    
    // recalculate frame
    CGFloat newWidth = 0;
    for (NSDictionary *dict in arrManaImages)
    {
        CGFloat dWidth = [dict[@"width"] floatValue];
        newWidth += dWidth;
    }
    
    self.lblCardName.frame = CGRectMake(self.lblCardName.frame.origin.x, self.lblCardName.frame.origin.y, self.lblCardName.frame.size.width+(self.viewManaCost.frame.size.width-newWidth), self.lblCardName.frame.size.height);
    
    self.viewManaCost.frame = CGRectMake(self.lblCardName.frame.origin.x+self.lblCardName.frame.size.width, self.viewManaCost.frame.origin.y, newWidth, self.viewManaCost.frame.size.height);
    
    // then re-add
    CGFloat dY = 0;
    CGFloat dX = 0;
    int index = 0;
    [self addSubview:self.lblCardName];
    [self addSubview:self.viewManaCost];
    for (NSDictionary *dict in arrManaImages)
    {
        CGFloat dWidth = [dict[@"width"] floatValue];
        CGFloat dHeight = [dict[@"height"] floatValue];
        dX = self.viewManaCost.frame.size.width - ((arrManaImages.count-index) * dWidth);
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:dict[@"path"]];

        UIImageView *imgMana = [[UIImageView alloc] initWithFrame:CGRectMake(dX, dY, dWidth, dHeight)];
        imgMana.contentMode = UIViewContentModeScaleAspectFit;
        imgMana.image = image;
        
        [self.viewManaCost addSubview:imgMana];
        index++;
    }
    
    [self showCardPricing];
}

-(void) addBadge:(int) badgeValue
{
    self.lblBadge.text = [NSString stringWithFormat:@"%dx", badgeValue];
    self.lblBadge.layer.backgroundColor = [UIColor redColor].CGColor;
    self.lblBadge.layer.cornerRadius = self.lblBadge.bounds.size.height / 4;
}

-(void) addRank:(int) rankValue
{
    self.lblRank.text = [NSString stringWithFormat:@"%d", rankValue];
    self.lblRank.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.lblRank.layer.cornerRadius = self.lblRank.bounds.size.height / 2;
}

-(void) showCardPricing
{
    NSNumberFormatter *formatter =  [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    [formatter setRoundingMode:NSNumberFormatterRoundCeiling];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    
    DTCard *card = [DTCard objectForPrimaryKey:self.cardId];
    
    NSString *price = card.tcgPlayerLowPrice != 0 ? [formatter stringFromNumber:[NSNumber numberWithDouble:card.tcgPlayerLowPrice]] : @"N/A";
    UIColor *color = card.tcgPlayerLowPrice != 0 ? [UIColor redColor] : [UIColor lightGrayColor];
    self.lblLowPrice.text = price;
    self.lblLowPrice.textColor = color;
    
    price = card.tcgPlayerMidPrice != 0 ? [formatter stringFromNumber:[NSNumber numberWithDouble:card.tcgPlayerMidPrice]] : @"N/A";
    color = card.tcgPlayerMidPrice != 0 ? [UIColor blueColor] : [UIColor lightGrayColor];
    self.lblMedianPrice.text = price;
    self.lblMedianPrice.textColor = color;
    
    price = card.tcgPlayerHighPrice != 0 ? [formatter stringFromNumber:[NSNumber numberWithDouble:card.tcgPlayerHighPrice]] : @"N/A";
    color = card.tcgPlayerHighPrice != 0 ? [JJJUtil colorFromHexString:@"#008000"] : [UIColor lightGrayColor];
    self.lblHighPrice.text = price;
    self.lblHighPrice.textColor = color;
    
    price = card.tcgPlayerFoilPrice != 0 ? [formatter stringFromNumber:[NSNumber numberWithDouble:card.tcgPlayerFoilPrice]] : @"N/A";
    color = card.tcgPlayerFoilPrice != 0 ? [JJJUtil colorFromHexString:@"#998100"] : [UIColor lightGrayColor];
    self.lblFoilPrice.text = price;
    self.lblFoilPrice.textColor = color;
}

-(void) loadCropImage:(id) sender
{
    NSString *cardId = [sender userInfo][@"cardId"];
    
    if ([self.cardId isEqualToString:cardId])
    {
        NSString *path = [[FileManager sharedInstance] cropPath:self.cardId];
        
        if (![path isEqualToString:_currentCropPath])
        {
            UIImage *hiResImage = [UIImage imageWithContentsOfFile: path];
            
            [UIView transitionWithView:self.imgCrop
                              duration:1
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.imgCrop.image = hiResImage;
                            } completion:nil];
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kCardDownloadCompleted
                                                      object:nil];
    }
}

-(void) parseSyncDone:(id) sender
{
    NSString *cardId = [sender userInfo][@"cardId"];
    
    if ([self.cardId isEqualToString:cardId])
    {
        DTCard *card = [DTCard objectForPrimaryKey:self.cardId];
        _ratingControl.rating = (float)card.rating;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kParseSyncDone
                                                      object:nil];
    }
}

@end
