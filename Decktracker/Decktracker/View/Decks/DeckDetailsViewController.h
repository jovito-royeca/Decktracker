//
//  DeckDetailsViewController.h
//  Decktracker
//
//  Created by Jovit Royeca on 9/4/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeckDetailsViewController : UIViewController<UITableViewDataSource, UITabBarDelegate>

@property(strong,nonatomic) NSDictionary *dictDeck;
@property(strong,nonatomic) UISegmentedControl *segmentedControl;
@property(strong,nonatomic) UITableView *tblData;

@end