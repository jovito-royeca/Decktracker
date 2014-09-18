//
//  Collection.h
//  Decktracker
//
//  Created by Jovit Royeca on 9/17/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

@import Foundation;

#import "Card.h"
typedef NS_ENUM(NSInteger, CollectionType)
{
    CollectionTypeRegular,
    CollectionTypeFoiled
};

@interface Collection : NSObject

@property(strong,nonatomic) NSString *name;
@property(strong,nonatomic) NSString *notes;
@property(strong,nonatomic) NSMutableArray *arrRegulars;
@property(strong,nonatomic) NSMutableArray *arrFoils;

-(id) initWithDictionary:(NSDictionary*) dict;
-(void) save:(NSString*) filePath;
-(void) updateCollection:(CollectionType) type withCard:(Card*) card withValue:(int) newValue;
-(int) cards:(Card*) card inType:(CollectionType) type;


@end
