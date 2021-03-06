//
//  Database.m
//  DeckTracker
//
//  Created by Jovit Royeca on 8/2/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "Database.h"
#import "Constants.h"

#import "TFHpple.h"

@implementation Database
{
    NSMutableArray *_parseQueue;
    NSArray *_currentParseQueue;
    NSMutableArray *_arrInAppSets;
}

static Database *_me;

+(id) sharedInstance
{
    if (!_me)
    {
        _me = [[Database alloc] init];
    }
    
    return _me;
}

-(id) init
{
    if (self = [super init])
    {
        _parseQueue = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark - Setup code
-(void) setupDb
{
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"decktracker.plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:filePath];
    
    NSString *jsonVersion = [dict objectForKey:@"JSON Version"];
    NSString *imagesVersion = [dict objectForKey:@"Images Version"];
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *storePath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", kDatabaseStore]];
    
#ifdef DEBUG
    NSLog(@"storePath=%@", storePath);
#endif
//    [RLMRealm setDefaultRealmPath:storePath];
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    [config setPath:storePath];
    [RLMRealmConfiguration setDefaultConfiguration:config];

    // delete all cards from mtgimage.com
    NSString *mtgImageKey = @"mtgimage.com images";
    if (![[NSUserDefaults standardUserDefaults] boolForKey:mtgImageKey])
    {
        NSString *path = [cachePath stringByAppendingPathComponent:@"/images/card"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }

        path = [cachePath stringByAppendingPathComponent:@"/images/crop"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:mtgImageKey];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:storePath])
    {
        NSString *preloadPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], kDatabaseStore];
        NSError* err = nil;
        
        if (![[NSFileManager defaultManager] copyItemAtPath:preloadPath toPath:storePath error:&err])
        {
            NSLog(@"Error: Unable to copy preloaded database.");
        }
        else
        {
            [[NSUserDefaults standardUserDefaults] setValue:jsonVersion forKey:@"JSON Version"];
            [[NSUserDefaults standardUserDefaults] setValue:imagesVersion forKey:@"Images Version"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    else
    {
        NSString *currentJSONVersion = [[NSUserDefaults standardUserDefaults] valueForKey:@"JSON Version"];
        
        if (!currentJSONVersion || ![jsonVersion isEqualToString:currentJSONVersion])
        {
            for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:nil])
            {
                if ([file hasPrefix:@"decktracker."])
                {
                    [[NSFileManager defaultManager] removeItemAtPath:[documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", file]]
                                                               error:nil];
                }
            }
            
            // cleanup Parse LocalDataStore
            [self cleanupParseLocalDataStore];
            
            [[NSUserDefaults standardUserDefaults] setValue:jsonVersion forKey:@"JSON Version"];
            [[NSUserDefaults standardUserDefaults] setValue:imagesVersion forKey:@"Images Version"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self setupDb];
        }
    }
    
    // delete core data files
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:nil])
    {
        if ([file hasSuffix:@"sqlite"] ||
            [file hasSuffix:@"sqlite-shm"] ||
            [file hasSuffix:@"sqlite-wal"])
        {
            [[NSFileManager defaultManager] removeItemAtPath:[documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", file]]
                                                       error:nil];
        }
    }

    [self loadInAppSets];
    
    // ignore database and other files from iCloud backup
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:nil])
    {
        if ([file hasPrefix:@"decktracker."])
        {
            NSURL *url = [[NSURL alloc] initFileURLWithPath:[documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", file]]];
            [JJJUtil addSkipBackupAttributeToItemAtURL:url];
        }
    }
    
#else
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *storePath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", kDatabaseStore]];
    
#ifdef DEBUG
    NSLog(@"storePath=%@", storePath);
#endif
    RLMRealmConfiguration *config = [[RLMRealmConfiguration alloc] init];
    [config setPath:storePath];
    [RLMRealmConfiguration setDefaultConfiguration:config];
#endif
}

-(void) migrateDb
{
    /*
    [RLMRealm setSchemaVersion:1
                forRealmAtPath:[RLMRealm defaultRealmPath]
            withMigrationBlock:^(RLMMigration *migration, uint64_t oldSchemaVersion)
    {
        // Add the 'fullName' property only to Realms with a schema version of 0
        if (oldSchemaVersion < 1)
        {
//            [migration enumerateObjects:Person.className
//                                  block:^(RLMObject *oldObject, RLMObject *newObject)
//            {
//                newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@", oldObject[@"firstName"], oldObject[@"lastName"]];
//            }];
        }
    }];*/
}

-(void) closeDb
{

}

-(void) copyRealmDatabaseToHome
{
    NSString *path = @"/Users/tontonsevilla/decktracker.realm";
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    [[RLMRealm defaultRealm] writeCopyToPath:path error:nil];
}

-(void) setupParse:(NSDictionary *)launchOptions
{
    [Parse enableLocalDatastore];
    [Parse setApplicationId:kParseID
                  clientKey:kParseClientKey];

#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
    [PFFacebookUtils initializeFacebook];
    [PFTwitterUtils initializeWithConsumerKey:kTwitterKey
                               consumerSecret:kTwitterSecret];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
#endif
}

-(void) cleanupParseLocalDataStore
{
    for (NSString *objectName in @[@"Card", @"CardRarity", @"CardRating", @"Set", @"Block", @"Artist", @"SetType"])
    {
        PFQuery *query = [PFQuery queryWithClassName:objectName];
        [query fromLocalDatastore];
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             for (PFObject *object in task.result)
             {
                 [object unpinInBackground];
             }
             return nil;
         }];
    }
}

#pragma mark - Finders
-(RLMResults*) findCards:(NSString*) query
     withSortDescriptors:(NSArray*) sorters
         withSectionName:(NSString*) sectionName
{
    NSPredicate *predicate;
    
    if (query.length == 0)
    {
        return nil;
    }
    else if (query.length == 1)
    {
        predicate = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[c] %@", @"name", query];
    }
    else
    {
        NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"%K CONTAINS[c] %@", @"name", query];
        NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"%K CONTAINS[c] %@", @"type", query];
        NSPredicate *pred3 = [NSPredicate predicateWithFormat:@"%K CONTAINS[c] %@", @"text", query];
        NSPredicate *pred4 = [NSPredicate predicateWithFormat:@"%K CONTAINS[c] %@", @"flavor", query];
        predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[pred1, pred2, pred3, pred4]];
    }
    
    // to do: exclude In-App Sets
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
    NSArray *inAppSetCodes = [self inAppSetCodes];
    if (inAppSetCodes.count > 0)
    {
        NSPredicate *predInAppSets = [NSPredicate predicateWithFormat:@"NOT (set.code IN %@)", inAppSetCodes];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, predInAppSets]];
    }
#endif

    return [[DTCard objectsWithPredicate:predicate] sortedResultsUsingDescriptors:sorters];
}

-(RLMResults*) findCards:(NSString*) query
           withPredicate:(NSPredicate*)predicate
     withSortDescriptors:(NSArray*) sorters
         withSectionName:(NSString*) sectionName
{
    NSPredicate *predicate2;
    
    if (query.length > 0)
    {
        if (query.length == 1)
        {
            NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"%K BEGINSWITH[c] %@", @"name", query];
            if (predicate)
            {
                predicate2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, pred1]];
            }
            else
            {
                predicate2 = pred1;
            }
        }
        else
        {
            NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"%K CONTAINS[c] %@", @"name", query];
            if (predicate)
            {
                predicate2 = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, pred1]];
            }
            else
            {
                predicate2 = pred1;
            }
        }
    }
    
    NSPredicate *pred = predicate2 ? predicate2 : predicate;
    
    // to do: exclude In-App Sets
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
    NSArray *inAppSetCodes = [self inAppSetCodes];
    if (inAppSetCodes.count > 0)
    {
        NSPredicate *predInAppSets = [NSPredicate predicateWithFormat:@"NOT (set.code IN %@)", inAppSetCodes];
        pred = [NSCompoundPredicate andPredicateWithSubpredicates:@[pred, predInAppSets]];
    }
#endif
    
    return [[DTCard objectsWithPredicate:pred] sortedResultsUsingDescriptors:sorters];
}

-(RLMResults*) advanceFindCards:(NSDictionary*)query
                    withSorters:(NSArray*) sorters
{
    NSMutableString *sql = [[NSMutableString alloc] init];
    NSMutableArray *arrParams = [[NSMutableArray alloc] init];
    NSString *defaultFieldName;
    NSArray *defaultFieldValues;
    
    for (NSString *key in [query allKeys])
    {
        NSString *fieldName;
        BOOL bToMany = NO;
        
        if ([key isEqualToString:@"Name"])
        {
            fieldName = @"name";
        }
        else if ([key isEqualToString:@"Set"])
        {
            fieldName = @"set.name";
//            bToMany = YES;
        }
        else if ([key isEqualToString:@"Format"])
        {
            fieldName = @"legalities.format.name";
            defaultFieldName = @"legalities.name";
            defaultFieldValues = @[@"Legal", @"Restricted"];
            bToMany = YES;
        }
        else if ([key isEqualToString:@"Rarity"])
        {
            fieldName = @"rarity.name";
//            bToMany = YES;
        }
        else if ([key isEqualToString:@"Type"])
        {
            fieldName = @"types.name";
            bToMany = YES;
        }
        else if ([key isEqualToString:@"Subtype"])
        {
            fieldName = @"subTypes.name";
            bToMany = YES;
        }
        else if ([key isEqualToString:@"Color"])
        {
            fieldName = @"sectionColor";
        }
        else if ([key isEqualToString:@"Keyword"])
        {
            fieldName = @"text";
        }
        else if ([key isEqualToString:@"Text"])
        {
            fieldName = @"originalText";
        }
        else if ([key isEqualToString:@"Flavor Text"])
        {
            fieldName = @"flavor";
        }
        else if ([key isEqualToString:@"Artist"])
        {
            fieldName = @"artist.name";
//            bToMany = YES;
        }
        else if ([key isEqualToString:@"Will Be Reprinted?"])
        {
            fieldName = @"reserved";
        }
        
        NSArray *arrQuery = query[key];
        if (arrQuery.count > 1)
        {
            NSDictionary *dict = [arrQuery firstObject];
            NSString *condition = [[dict allKeys] firstObject];
            
            if (sql.length > 0)
            {
                [sql appendFormat:@" %@ (", condition];
            }
            else
            {
                [sql appendFormat:@"("];
            }
            
            for (NSDictionary *dict2 in arrQuery)
            {
                condition = [[dict2 allKeys] firstObject];
                id value = dict2[condition];
                
                if ([value isEqualToString:@"Yes"])
                {
                    value = [NSNumber numberWithBool:NO];
                }
                else if ([value isEqualToString:@"No"])
                {
                    value = [NSNumber numberWithBool:YES];
                }
                
                if ([arrQuery indexOfObject:dict2] != 0)
                {
                    [sql appendFormat:@" %@ ", condition];
                    
                }
                
                if (bToMany)
                {
                    [sql appendFormat:@"ANY %@ == %%@", fieldName];
                }
                else
                {
                    if ([value isKindOfClass:[NSNumber class]])
                    {
                        [sql appendFormat:@"ANY %@ CONTAINS[c] %%@", fieldName];
                    }
                    else
                    {
                        if (((NSString*)value).length == 1)
                        {
                            [sql appendFormat:@"%@ BEGINSWITH[c] %%@", fieldName];
                        }
                        else
                        {
                            [sql appendFormat:@"%@ CONTAINS[c] %%@", fieldName];
                        }
                    }
                }
                [arrParams addObject:value];
            }
            [sql appendString:@")"];
        }
        
        else
        {
            NSDictionary *dict = [arrQuery firstObject];
            NSString *condition = [[dict allKeys] firstObject];
            id value = dict[condition];
            
            if ([value isEqualToString:@"Yes"])
            {
                value = [NSNumber numberWithBool:NO];
            }
            else if ([value isEqualToString:@"No"])
            {
                value = [NSNumber numberWithBool:YES];
            }
            
            if (sql.length > 0)
            {
                [sql appendFormat:@" %@ ", condition];
            }
            
            if (bToMany)
            {
                [sql appendFormat:@"ANY %@ CONTAINS[c] %%@", fieldName];
            }
            else
            {
                if ([value isKindOfClass:[NSNumber class]])
                {
                    [sql appendFormat:@"%@ == %%@", fieldName];
                }
                else
                {
                    if (((NSString*)value).length == 1)
                    {
                        [sql appendFormat:@"%@ BEGINSWITH[c] %%@", fieldName];
                    }
                    else
                    {
                        [sql appendFormat:@"%@ CONTAINS[c] %%@", fieldName];
                    }
                }
                
            }
            [arrParams addObject:value];
        }
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:sql argumentArray:arrParams];
    if (defaultFieldName && defaultFieldValues)
    {
        NSPredicate *predDefault = [NSPredicate predicateWithFormat:@"ANY %K IN %@", defaultFieldName, defaultFieldValues];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, predDefault]];
    }
    
    // to do: exclude In-App Sets
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
    NSArray *inAppSetCodes = [self inAppSetCodes];
    if (inAppSetCodes.count > 0)
    {
        NSPredicate *predInAppSets = [NSPredicate predicateWithFormat:@"NOT (set.code IN %@)", inAppSetCodes];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, predInAppSets]];
    }
#endif
    
    return [[DTCard objectsWithPredicate:predicate] sortedResultsUsingDescriptors:sorters];
}


-(NSArray*) fetchRandomCardsFromFormats:(NSArray*) formats
                         excludeFormats:(NSArray*) excludeFormats
                                howMany:(int) howMany
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"format.name IN %@ AND NOT (format.name IN %@) AND card.set.magicCardsInfoCode != %@ AND (card.cmc >= 1 AND card.cmc <= 15)", formats, excludeFormats, @""];
        
    RLMResults *results = [DTCardLegality objectsWithPredicate:predicate];
        
    if (results.count > 0)
    {
        for (int i=0; i<howMany; i++)
        {
            int random = arc4random() % (results.count - 1) + 1;
            DTCardLegality *legality = [results objectAtIndex:random+1];
            [array addObject:legality.card];
        }
    }
        
    return array;
}
 
-(void) fetchTcgPlayerPriceForCard:(NSString*) cardId
{
    __block DTCard *card = [DTCard objectForPrimaryKey:cardId];
    BOOL bWillFetch = NO;
        
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitHour
                                                fromDate:card.tcgPlayerFetchDate
                                                  toDate:today
                                                 options:0];
    if ([components hour] >= TCGPLAYER_FETCH_STORAGE)
    {
        bWillFetch = YES;
    }
        
    if (card.set.tcgPlayerName.length <= 0)
    {
        bWillFetch = NO;
    }
        
    if (bWillFetch)
    {
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            card = [DTCard objectForPrimaryKey:cardId];
#endif
            NSString *tcgPricing = [[NSString stringWithFormat:@"http://partner.tcgplayer.com/x3/phl.asmx/p?pk=%@&s=%@&p=%@", TCGPLAYER_PARTNER_KEY, card.set.tcgPlayerName, card.name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if (!card.set.tcgPlayerName)
            {
                tcgPricing = [[NSString stringWithFormat:@"http://partner.tcgplayer.com/x3/phl.asmx/p?pk=%@&p=%@", TCGPLAYER_PARTNER_KEY, card.name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            }
                
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:tcgPricing]];
            TFHpple *parser = [TFHpple hppleWithHTMLData:data];
            NSString *low, *mid, *high, *foil, *link;
                
            NSArray *nodes = [parser searchWithXPathQuery:@"//product"];
            for (TFHppleElement *element in nodes)
            {
                if ([element hasChildren])
                {
                    BOOL linkIsNext = NO;
                        
                    for (TFHppleElement *child in element.children)
                    {
                        if ([[child tagName] isEqualToString:@"hiprice"])
                        {
                            high = [[child firstChild] content];
                        }
                        else if ([[child tagName] isEqualToString:@"avgprice"])
                        {
                            mid = [[child firstChild] content];
                        }
                        else if ([[child tagName] isEqualToString:@"lowprice"])
                        {
                            low = [[child firstChild] content];
                        }
                        else if ([[child tagName] isEqualToString:@"foilavgprice"])
                        {
                            foil = [[child firstChild] content];
                        }
                        else if ([[child tagName] isEqualToString:@"link"])
                        {
                            linkIsNext = YES;
                        }
                        else if ([[child tagName] isEqualToString:@"text"] && linkIsNext)
                        {
                            link = [child content];
                        }
                    }
                }
            }
#ifdef DEBUG
            NSLog(@"^TCGPlayer: %@ [%@] - %@", card.set.name, card.set.code, card.name);
#endif
                
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
                
            card.tcgPlayerHighPrice = high ? [high doubleValue] : card.tcgPlayerHighPrice;
            card.tcgPlayerMidPrice  = mid  ? [mid doubleValue]  : card.tcgPlayerMidPrice;
            card.tcgPlayerLowPrice  = low  ? [low doubleValue]  : card.tcgPlayerLowPrice;
            card.tcgPlayerFoilPrice = foil ? [foil doubleValue] : card.tcgPlayerFoilPrice;
            card.tcgPlayerLink = link ? [JJJUtil trim:link] : card.tcgPlayerLink;
            card.tcgPlayerFetchDate = [NSDate date];
            [realm commitWriteTransaction];
                
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
            dispatch_async(dispatch_get_main_queue(), ^{
#endif
                [[NSNotificationCenter defaultCenter] postNotificationName:kPriceUpdateDone
                                                                    object:nil
                                                                  userInfo:@{@"cardId": cardId}];
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
            });
        });
#endif
    }
        
    else
    {
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
        dispatch_async(dispatch_get_main_queue(), ^{
#endif
            [[NSNotificationCenter defaultCenter] postNotificationName:kPriceUpdateDone
                                                                object:nil
                                                              userInfo:@{@"cardId": cardId}];
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
        });
#endif
    }
}
     
-(NSArray*) fetchSets:(int) howMany
{
    RLMSortDescriptor *sortDescriptor1 = [RLMSortDescriptor sortDescriptorWithProperty:@"releaseDate"
                                                                             ascending:NO];
    RLMSortDescriptor *sortDescriptor2 = [RLMSortDescriptor  sortDescriptorWithProperty:@"name"
                                                                              ascending:YES];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"magicCardsInfoCode != nil"];
        
    NSMutableArray *arrResults = [[NSMutableArray alloc] init];
    RLMResults *sets = [[DTSet objectsWithPredicate:predicate] sortedResultsUsingDescriptors:@[sortDescriptor1, sortDescriptor2]];
        
    for (int i=0; i<howMany; i++)
    {
        DTSet *set = [sets objectAtIndex:i];
        [arrResults addObject:set.setId];
    }
    return arrResults;
}
     
#if defined(_OS_IPHONE) || defined(_OS_IPHONE_SIMULATOR)
-(void) loadInAppSets
{
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], @"In-App Sets.plist"];
    _arrInAppSets = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict in [NSArray arrayWithContentsOfFile:filePath])
    {
        if (![InAppPurchase isProductPurchased:dict[@"In-App Product ID"]])
        {
            [_arrInAppSets addObject:dict];
        }
    }
}

-(NSDictionary*) inAppSettingsForSet:(NSString*) setId
{
    DTSet *set = [DTSet objectForPrimaryKey:setId];
    
    for (NSDictionary *dict in _arrInAppSets)
    {
        if ([dict[@"Name"] isEqualToString:set.name] &&
            [dict[@"Code"] isEqualToString:set.code])
        {
            return dict;
        }
    }
    return nil;
}

-(NSArray*) inAppSetCodes
{
    NSMutableArray *arrSetCodes = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict in _arrInAppSets) {
        [arrSetCodes addObject:dict[@"Code"]];
    }
    
    return arrSetCodes;
}

-(BOOL) isSetPurchased:(DTSet*) set
{
    NSArray *inAppSetCodes = [self inAppSetCodes];
    
    if (inAppSetCodes.count > 0)
    {
        for (NSString *code in inAppSetCodes)
        {
            if ([set.code isEqualToString:code])
            {
                return NO;
            }
        }
    }
    
    return YES;
}

-(NSArray*) fetchRandomCards:(int) howMany
               withPredicate:(NSPredicate*) predicate
        includeInAppPurchase:(BOOL) inAppPurchase
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    RLMSortDescriptor *sortDescriptor1 = [RLMSortDescriptor sortDescriptorWithProperty:@"name" ascending:YES];
//    RLMSortDescriptor *sortDescriptor2 = [RLMSortDescriptor sortDescriptorWithProperty:@"set.releaseDate" ascending:NO];
    
    if (!inAppPurchase)
    {
        NSArray *inAppSetCodes = [self inAppSetCodes];
        if (inAppSetCodes.count > 0)
        {
            NSPredicate *predInAppSets = [NSPredicate predicateWithFormat:@"NOT (set.code IN %@)", inAppSetCodes];
            
            predicate = predicate ? [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, predInAppSets]] : predInAppSets;
        }
    }
    
    // do not include cards without images
    NSPredicate *predWithoutImages = [NSPredicate predicateWithFormat:@"set.magicCardsInfoCode != %@", @""];
    predicate = predicate ? [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, predWithoutImages]] : predWithoutImages;
    
    RLMResults *results = [[DTCard objectsWithPredicate:predicate] sortedResultsUsingDescriptors:@[sortDescriptor1/*, sortDescriptor2*/]];
    
    if (results.count > 0)
    {
        for (int i=0; i<howMany; i++)
        {
            int random = arc4random() % (results.count - 1) + 1;
            [array addObject:[results objectAtIndex:random+1]];
        }
    }
    
    return array;
}
#endif
     
#pragma mark - Parse methods
-(void) fetchTopRated:(int) limit skip:(int) skip
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"rating >= 0"];
    PFQuery *query = [PFQuery queryWithClassName:@"Card" predicate:predicate];
    [query orderByDescending:@"rating"];
    [query addAscendingOrder:@"name"];
    [query whereKeyExists:@"rating"];
    [query includeKey:@"set"];

    if (limit >= 0)
    {
        query.limit = limit;
    }
    query.limit = limit;
    if (skip >= 0)
    {
        query.skip = skip;
    }
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        NSMutableArray *arrResults = [[NSMutableArray alloc] init];
        
        if (!error)
        {
            RLMRealm *realm = [RLMRealm defaultRealm];
            
            for (PFObject *object in objects)
            {
                NSPredicate *p = object[@"number"] ? [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)", @"name", object[@"name"], @"number", object[@"number"], @"set.name", object[@"set"][@"name"]] :
                [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@", @"name", object[@"name"], @"set.name", object[@"set"][@"name"]];
                
                DTCard *card = [[DTCard objectsWithPredicate:p] firstObject];
                
                if (card)
                {
                    [realm beginWriteTransaction];
                    card.rating = [object[@"rating"] doubleValue];
                    [realm commitWriteTransaction];
                    [arrResults addObject:card.cardId];
                }
            }
        }
        else
        {
            RLMSortDescriptor *sortDescriptor1 = [RLMSortDescriptor sortDescriptorWithProperty:@"rating"
                                                                                     ascending:NO];
            RLMSortDescriptor *sortDescriptor2 = [RLMSortDescriptor sortDescriptorWithProperty:@"name"
                                                                                     ascending:YES];
            
            RLMResults *results = [[DTCard objectsWithPredicate:[NSPredicate predicateWithFormat:@"rating >= 0"]] sortedResultsUsingDescriptors:@[sortDescriptor1, sortDescriptor2]];
            for (int i=0; i<limit; i++)
            {
                DTCard *card = [results objectAtIndex:i];
                [arrResults addObject:card.cardId];
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kFetchTopRatedDone
                                                            object:nil
                                                          userInfo:@{@"cardIds": arrResults}];
    }];
}

-(void) fetchTopViewed:(int) limit skip:(int) skip
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"numberOfViews >= 0"];
    PFQuery *query = [PFQuery queryWithClassName:@"Card" predicate:predicate];
    [query orderByDescending:@"numberOfViews"];
    [query addAscendingOrder:@"name"];
    [query includeKey:@"set"];

    if (limit >= 0)
    {
        query.limit = limit;
    }
    query.limit = limit;
    if (skip >= 0)
    {
        query.skip = skip;
    }
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        NSMutableArray *arrResults = [[NSMutableArray alloc] init];
        
        if (!error)
        {
            for (PFObject *object in objects)
            {
                NSPredicate *p = object[@"number"] ? [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@ AND %K = %@)", @"name", object[@"name"], @"number", object[@"number"], @"set.name", object[@"set"][@"name"]] :
                [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@", @"name", object[@"name"], @"set.name", object[@"set"][@"name"]];
                
                DTCard *card = [[DTCard objectsWithPredicate:p] firstObject];
                if (card)
                {
                    [arrResults addObject:card.cardId];
                }
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kFetchTopViewedDone
                                                            object:nil
                                                          userInfo:@{@"cardIds": arrResults}];
    }];
}

-(void) incrementCardView:(NSString*) cardId
{
    void (^callbackIncrementCard)(PFObject *pfCard, NSString* kardId) = ^void(PFObject *pfCard, NSString* kardId) {
        
        __block DTCard *card = [DTCard objectForPrimaryKey:kardId];
        [pfCard incrementKey:@"numberOfViews"];
        
        [pfCard saveEventually:^(BOOL success, NSError *error) {
            if (pfCard[@"rating"])
            {
                card = [DTCard objectForPrimaryKey:kardId];
                
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                card.rating = [pfCard[@"rating"] doubleValue];
                card.parseFetchDate = [NSDate date];
                [realm commitWriteTransaction];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kParseSyncDone
                                                                object:nil
                                                              userInfo:@{@"cardId": kardId}];
            
            _currentParseQueue = nil;
            [self processQueue];
        }];
    };
    
    [_parseQueue addObject:@[cardId, callbackIncrementCard]];
    [self processQueue];
}

-(void) rateCard:(NSString*) cardId withRating:(float) rating
{
    void (^callbackRateCard)(PFObject *pfCard, NSString* kardId) = ^void(PFObject *pfCard, NSString* kardId) {
        PFObject *pfRating = [PFObject objectWithClassName:@"CardRating"];
        pfRating[@"rating"] = [NSNumber numberWithDouble:rating];
        pfRating[@"card"] = pfCard;
        
        [pfRating saveEventually:^(BOOL success, NSError *error) {
            PFQuery *query = [PFQuery queryWithClassName:@"CardRating"];
            [query whereKey:@"card" equalTo:pfCard];
            
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                __block DTCard *card = [DTCard objectForPrimaryKey:kardId];
                double totalRating = 0;
                double averageRating = 0;
                
                for (PFObject *object in objects)
                {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    DTCardRating *rating = [[DTCardRating alloc] init];
                    rating.rating = [object[@"rating"] floatValue];
                    rating.card = card;
                    [realm addObject:rating];
                    [realm commitWriteTransaction];
                    
                    totalRating += [object[@"rating"] doubleValue];
                }
                
                averageRating = totalRating/objects.count;
                if (isnan(averageRating))
                {
                    averageRating = 0;
                }
                
                pfCard[@"rating"] = [NSNumber numberWithDouble:averageRating];
                [pfCard saveEventually:^(BOOL success, NSError *error) {
                    card = [DTCard objectForPrimaryKey:kardId];
                    
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    card.rating = averageRating;
                    card.parseFetchDate = [NSDate date];
                    [realm commitWriteTransaction];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kParseSyncDone
                                                                        object:nil
                                                                      userInfo:@{@"cardId": kardId}];
                    _currentParseQueue = nil;
                    [self processQueue];
                }];
            }];
        }];
    };
    
    [_parseQueue addObject:@[cardId, callbackRateCard]];
    [self processQueue];
}

-(void) fetchCardRating:(NSString*) cardId
{
    DTCard *card = [DTCard objectForPrimaryKey:cardId];
    BOOL bWillFetch = NO;
    
    NSDate *today = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitHour
                                                fromDate:card.parseFetchDate
                                                  toDate:today
                                                 options:0];
    if ([components hour] >= PARSE_FETCH_STORAGE)
    {
        bWillFetch = YES;
    }
    
    if (bWillFetch)
    {
        void (^callbackFetchCardRating)(PFObject *pfCard, NSString* kardId) = ^void(PFObject *pfCard, NSString* kardId) {
            
            if (pfCard[@"rating"])
            {
                DTCard *kard = [DTCard objectForPrimaryKey:kardId];
                
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                kard.rating = [pfCard[@"rating"] doubleValue];
                kard.parseFetchDate = [NSDate date];
                [realm commitWriteTransaction];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kParseSyncDone
                                                                object:nil
                                                              userInfo:@{@"cardId": kardId}];
            _currentParseQueue = nil;
            [self processQueue];
        };
        
        [_parseQueue addObject:@[cardId, callbackFetchCardRating]];
    }
    
    [self processQueue];
}

-(void) fetchUserMana
{
    PFUser *currentUser = [PFUser currentUser];
    
    if (!currentUser)
    {
        [self mergeLocalUserManaWithRemote:nil];
    }
    else
    {
        // find remotely first
        __block PFQuery *query = [PFQuery queryWithClassName:@"UserMana"];
        [query whereKey:@"user" equalTo:currentUser];
        
        [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task)
        {
            return [[PFObject unpinAllObjectsInBackgroundWithName:@"UserMana"] continueWithSuccessBlock:^id(BFTask *ignored)
            {
                NSArray *results = task.result;
                         
                if (results.count > 0)
                {
                    // found remotely
                    PFObject *remoteUserMana = task.result[0];
                    [self mergeLocalUserManaWithRemote:remoteUserMana];
                }
                else
                {
                    // not found remotely
                    [self mergeLocalUserManaWithRemote:nil];
                }
                 
                return task;
             }];
        }];
    }
}

-(void) saveUserMana:(PFObject*) userMana
{
    PFUser *currentUser = [PFUser currentUser];
    
    if (!currentUser)
    {
        [userMana pinInBackgroundWithBlock:^void(BOOL succeeded, NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kParseUserManaDone
                                                                object:nil
                                                              userInfo:@{@"userMana": userMana}];
        }];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kParseUserManaDone
                                                            object:nil
                                                          userInfo:@{@"userMana": userMana}];
        
        if (userMana)
        {
            userMana[@"user"] = currentUser;
            [userMana saveEventually];
        }
        [self deleteUserManaLocally];
    }
}

-(void) deleteUserManaLocally
{
    __block PFQuery *query = [PFQuery queryWithClassName:@"UserMana"];
    [query fromLocalDatastore];
    
    [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
     {
         PFObject *pfUserMana;
         
         if (task.error)
         {
             return task;
         }
         
         for (PFObject *object in task.result)
         {
             pfUserMana = object;
             [pfUserMana unpinInBackground];
         }
         return task;
     }];
}

-(void) fetchLeaderboard
{
    NSMutableArray *arrResults = [[NSMutableArray alloc] init];
    PFQuery *query = [PFQuery queryWithClassName:@"UserMana"];
    query.limit = 15;
    
    [query includeKey:@"user"];
    [query orderByDescending:@"totalCMC"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error)
        {
            [arrResults addObjectsFromArray:objects];
        }
        else
        {
            NSLog(@"%@", error);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kParseLeaderboardDone
                                                            object:nil
                                                          userInfo:@{@"leaderboard": arrResults}];
    }];
}

#pragma mark - Parse Queue
-(void) updateCard:(PFObject*) pfCard
          existing:(BOOL) existing
        withCardId:(NSString*) cardId
            andSet:(PFObject*) pfSet
         andRarity:(PFObject*) pfRarity
         andArtist:(PFObject*) pfArtist
      andPrintings:(NSArray*) pfPrintings
       andCallback:(void (^)(PFObject*, NSString*kardId)) callback
{
    
#ifndef DEBUG
    // don't update Parse if deployed in Production
    if (existing)
    {
        callback(pfCard, cardId);
        return;
    }
#endif
    
    __block DTCard *card = [DTCard objectForPrimaryKey:cardId];
    
    if (card.border.length > 0)
    {
        pfCard[@"border"] = card.border;
    }
    else
    {
        [pfCard removeObjectForKey:@"border"];
    }
    
    if (card.cmc != -1)
    {
        pfCard[@"cmc"] = [NSNumber numberWithFloat:card.cmc];
    }
    else
    {
        [pfCard removeObjectForKey:@"cmc"];
    }
    
    if (card.flavor.length > 0)
    {
        pfCard[@"flavor"] = card.flavor;
    }
    else
    {
        [pfCard removeObjectForKey:@"flavor"];
    }
    
    if (card.handModifier != -1)
    {
        pfCard[@"handModifier"] = [NSNumber numberWithInt:card.handModifier];
    }
    else
    {
        [pfCard removeObjectForKey:@"handModifier"];
    }
    
    if (card.imageName.length > 0)
    {
        pfCard[@"imageName"] = card.imageName;
    }
    else
    {
        [pfCard removeObjectForKey:@"imageName"];
    }
    
    if (card.layout.length > 0)
    {
        pfCard[@"layout"] = card.layout;
    }
    else
    {
        [pfCard removeObjectForKey:@"layout"];
    }
    
    if (card.lifeModifier != -1)
    {
        pfCard[@"lifeModifier"] = [NSNumber numberWithInt:card.lifeModifier];
    }
    else
    {
        [pfCard removeObjectForKey:@"lifeModifier"];
    }
    
    if (card.loyalty != -1)
    {
        pfCard[@"loyalty"] = [NSNumber numberWithInt:card.loyalty];
    }
    else
    {
        [pfCard removeObjectForKey:@"loyalty"];
    }
    
    if (card.manaCost.length > 0)
    {
        pfCard[@"manaCost"] = card.manaCost;
    }
    else
    {
        [pfCard removeObjectForKey:@"manaCOst"];
    }
    
    pfCard[@"modern"] = [NSNumber numberWithBool:card.modern];
    
    if (card.multiverseID != -1)
    {
        pfCard[@"multiverseID"] = [NSNumber numberWithInt:card.multiverseID];
    }
    else
    {
        [pfCard removeObjectForKey:@"multiverseID"];
    }
    
    if (card.name.length > 0)
    {
        pfCard[@"name"] = card.name;
    }
    else
    {
        [pfCard removeObjectForKey:@"name"];
    }
    
    if (card.number.length > 0)
    {
        pfCard[@"number"] = card.number;
    }
    else
    {
        [pfCard removeObjectForKey:@"number"];
    }
    
    if (card.originalText.length > 0)
    {
        pfCard[@"originalText"] = card.originalText;
    }
    else
    {
        [pfCard removeObjectForKey:@"originalText"];
    }
    
    if (card.originalType.length > 0)
    {
        pfCard[@"originalType"] = card.originalType;
    }
    else
    {
        [pfCard removeObjectForKey:@"originalType"];
    }
    
    if (card.power.length > 0)
    {
        pfCard[@"power"] = card.power;
    }
    else
    {
        [pfCard removeObjectForKey:@"power"];
    }
    
    if (card.releaseDate.length > 0)
    {
        pfCard[@"releaseDate"] = card.releaseDate;
    }
    else
    {
        [pfCard removeObjectForKey:@"releaseDate"];
    }
    
    pfCard[@"reserved"] = [NSNumber numberWithBool:card.reserved];
    
    if (card.source.length > 0)
    {
        pfCard[@"source"] = card.source;
    }
    else
    {
        [pfCard removeObjectForKey:@"source"];
    }
    
    pfCard[@"starter"] = [NSNumber numberWithBool:card.starter];
    
    if (card.text.length > 0)
    {
        pfCard[@"text"] = card.text;
    }
    else
    {
        [pfCard removeObjectForKey:@"text"];
    }
    
    pfCard[@"timeshifted"] = [NSNumber numberWithBool:card.timeshifted];
    
    if (card.toughness.length > 0)
    {
        pfCard[@"toughness"] = card.toughness;
    }
    else
    {
        [pfCard removeObjectForKey:@"toughness"];
    }
    
    if (card.type.length > 0)
    {
        pfCard[@"type"] = card.type;
    }
    else
    {
        [pfCard removeObjectForKey:@"type"];
    }
    
    if (card.watermark.length > 0)
    {
        pfCard[@"watermark"] = card.watermark;
    }
    else
    {
        [pfCard removeObjectForKey:@"watermark"];
    }
    
    PFRelation *relation = [pfCard relationForKey:@"printings"];
    for (PFObject *pfSet2 in pfPrintings)
    {
        [relation addObject:pfSet2];
    }
    pfCard[@"set"] = pfSet;
    pfCard[@"rarity"] = pfRarity;
    pfCard[@"artist"] = pfArtist;
    
    [pfCard saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
#ifdef DEBUG
        if (error)
        {
            card = [DTCard objectForPrimaryKey:cardId];
            NSLog(@"Error saving Card: %@ : %@", card.name, error.description);
        }
#endif
        
        if (success)
        {
            [pfCard pinInBackgroundWithBlock:^(BOOL success, NSError *error) {
#ifdef DEBUG
                DTCard *card = [DTCard objectForPrimaryKey:cardId];
                NSLog(@"%@Parse: %@ [%@]", (existing ? @"^":@"+"), card.name, card.set.code);
#endif
                callback(pfCard, cardId);
            }];
        }
        else
        {
            _currentParseQueue = nil;
            [self processQueue];
        }
    }];
}

-(void) processCurrentParseQueue
{
    NSString *cardId = _currentParseQueue[0];
    void (^callbackTask)(PFObject *pfCard, NSString* kardId) = _currentParseQueue[1];
    
    void (^callbackFindCard)(NSString *cardId, PFObject *pfSet, PFObject *pfRarity, PFObject *pfArtist, NSArray *pfPrintings) = ^void(NSString *cardId, PFObject *pfSet, PFObject *pfRarity, PFObject *pfArtist, NSArray *pfPrintings)
    {
        __block DTCard *card = [DTCard objectForPrimaryKey:cardId];
        __block PFQuery *query = [PFQuery queryWithClassName:@"Card"];
        [query whereKey:@"name" equalTo:card.name];
        if (card.multiverseID == -1)
        {
            [query whereKey:@"number" equalTo:card.number];
        }
        else
        {
            [query whereKey:@"multiverseID" equalTo:[NSNumber numberWithInt:card.multiverseID]];
        }
        [query whereKey:@"set" equalTo:pfSet];
        [query fromLocalDatastore];
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             if (task.error)
             {
                 return task;
             }
             
             __block PFObject *pfCard;
             
             for (PFObject *object in task.result)
             {
                 pfCard = object;
             }
             
             if (pfCard)
             {
                 [self updateCard:pfCard
                         existing:YES
                       withCardId:cardId
                           andSet:pfSet
                        andRarity:pfRarity
                        andArtist:pfArtist
                     andPrintings:pfPrintings
                      andCallback:callbackTask];
             }
             else
             {
                 // not found in local datastore, find remotely
                 card = [DTCard objectForPrimaryKey:cardId];
                 query = [PFQuery queryWithClassName:@"Card"];
                 [query whereKey:@"name" equalTo:card.name];
                 if (card.multiverseID == -1)
                 {
                     [query whereKey:@"number" equalTo:card.number];
                 }
                 else
                 {
                     [query whereKey:@"multiverseID" equalTo:[NSNumber numberWithInt:card.multiverseID]];
                 }
                 [query whereKey:@"set" equalTo:pfSet];
                 
                 [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task)
                  {
                      NSArray *results = task.result;
                      BOOL existing = YES;
                      
                      if (results.count > 0)
                      {
                          pfCard = task.result[0];
                      }
                      else
                      {
                          // not found remotely, create new
                          pfCard = [PFObject objectWithClassName:@"Card"];
                          existing = NO;
                      }
                      
                      [self updateCard:pfCard
                              existing:existing
                            withCardId:cardId
                                andSet:pfSet
                             andRarity:pfRarity
                             andArtist:pfArtist
                          andPrintings:pfPrintings
                           andCallback:callbackTask];
                      
                      return task;
                  }];
             }
             
             return task;
         }];
    };
    
    void (^callbackFindPrintings)(NSString *cardId, PFObject *pfSet, PFObject *pfCardRarity, PFObject *pfArtist) = ^void(NSString *cardId, PFObject *pfSet, PFObject *pfCardRarity, PFObject *pfArtist)
    {
        
        __block DTCard *card = [DTCard objectForPrimaryKey:cardId];
        __block PFQuery *query = [PFQuery queryWithClassName:@"Set"];
        __block NSMutableArray *arrSetNames = [[NSMutableArray alloc] init];
        for (DTSet *set in card.printings)
        {
            [arrSetNames addObject:set.name];
        }
        
        [query whereKey:@"name" containedIn:arrSetNames];
        [query fromLocalDatastore];
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             card = [DTCard objectForPrimaryKey:cardId];
             __block NSMutableArray *pfPrintings = [[NSMutableArray alloc] init];
             
             if (task.error)
             {
                 return task;
             }
             
             for (PFObject *object in task.result)
             {
                 [pfPrintings addObject:object];
             }
             
             if (pfPrintings.count == card.printings.count)
             {
                 callbackFindCard(cardId, pfSet, pfCardRarity, pfArtist, pfPrintings);
             }
             else
             {
                 // not found in local datastore, find remotely
                 query = [PFQuery queryWithClassName:@"Set"];
                 arrSetNames = [[NSMutableArray alloc] init];
                 for (DTSet *set in card.printings)
                 {
                     [arrSetNames addObject:set.name];
                 }
                 [query whereKey:@"name" containedIn:arrSetNames];
                 
                 [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task)
                  {
                      pfPrintings = [[NSMutableArray alloc] init];
                      
                      for (PFObject *object in task.result)
                      {
                          [pfPrintings addObject:object];
                      }
                      
                      for (int i=0; i<pfPrintings.count; i++)
                      {
                          [pfPrintings[i] pinInBackgroundWithBlock:^(BOOL success, NSError *error)
                           {
                               if (i == pfPrintings.count -1)
                               {
                                   callbackFindCard(cardId, pfSet, pfCardRarity, pfArtist, pfPrintings);
                               }
                           }];
                      }
                      
                      return task;
                  }];
             }
             
             return task;
         }];
    };
    
    void (^callbackFindSet)(NSString *cardId, PFObject *pfCardRarity, PFObject *pfArtist) = ^void(NSString *cardId, PFObject *pfCardRarity, PFObject *pfArtist)
    {
        __block DTCard *card = [DTCard objectForPrimaryKey:cardId];
        __block PFQuery *query = [PFQuery queryWithClassName:@"Set"];
        [query whereKey:@"name" equalTo:card.set.name];
        [query whereKey:@"code" equalTo:card.set.code];
        [query fromLocalDatastore];
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             __block PFObject *pfSet;
             
             if (task.error)
             {
                 return task;
             }
             
             for (PFObject *object in task.result)
             {
                 pfSet = object;
             }
             
             if (pfSet)
             {
                 callbackFindPrintings(cardId, pfSet, pfCardRarity, pfArtist);
             }
             else
             {
                 // not found in local datastore, find remotely
                 card = [DTCard objectForPrimaryKey:cardId];
                 query = [PFQuery queryWithClassName:@"Set"];
                 [query whereKey:@"name" equalTo:card.set.name];
                 [query whereKey:@"code" equalTo:card.set.code];
                 
                 [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task)
                  {
                      card = [DTCard objectForPrimaryKey:cardId];
                      NSArray *results = task.result;
                      
                      if (results.count > 0)
                      {
                          pfSet = task.result[0];
                      }
                      else
                      {
                          // not found remotely
                          pfSet = [PFObject objectWithClassName:@"Set"];
                          pfSet[@"name"] = card.set.name;
                          pfSet[@"code"] = card.set.code;
                      }
                      
                      [pfSet pinInBackgroundWithBlock:^(BOOL success, NSError *error)
                       {
                           callbackFindPrintings(cardId, pfSet, pfCardRarity, pfArtist);
                       }];
                      
                      return task;
                  }];
             }
             
             return task;
         }];
    };
    
    void (^callbackFindArtist)(NSString *cardId, PFObject *pfCardRarity) = ^void(NSString *cardId, PFObject *pfCardRarity)
    {
        __block DTCard *card = [DTCard objectForPrimaryKey:cardId];
        __block PFQuery *query = [PFQuery queryWithClassName:@"Artist"];
        [query whereKey:@"name" equalTo:card.artist.name];
        [query fromLocalDatastore];
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             __block PFObject *pfArtist;
             
             if (task.error)
             {
                 return task;
             }
             
             for (PFObject *object in task.result)
             {
                 pfArtist = object;
             }
             
             if (pfArtist)
             {
                 callbackFindSet(cardId, pfCardRarity, pfArtist);
             }
             else
             {
                 // not found in local datastore, find remotely
                 card = [DTCard objectForPrimaryKey:cardId];
                 query = [PFQuery queryWithClassName:@"Artist"];
                 [query whereKey:@"name" equalTo:card.artist.name];
                 
                 [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task)
                  {
                      card = [DTCard objectForPrimaryKey:cardId];
                      NSArray *results = task.result;
                      
                      if (results.count > 0)
                      {
                          pfArtist = task.result[0];
                      }
                      else
                      {
                          // not found remotely
                          pfArtist = [PFObject objectWithClassName:@"Artist"];
                          pfArtist[@"name"] = card.artist.name;
                      }
                      
                      [pfArtist pinInBackgroundWithBlock:^(BOOL success, NSError *error)
                       {
                           callbackFindSet(cardId, pfCardRarity, pfArtist);
                       }];
                      return task;
                  }];
             }
             
             return task;
         }];
    };
    
    void (^callbackFindCardRarity)(NSString *cardId) = ^void(NSString *cardId)
    {
        __block DTCard *card = [DTCard objectForPrimaryKey:cardId];
        __block PFQuery *query = [PFQuery queryWithClassName:@"CardRarity"];
        [query whereKey:@"name" equalTo:card.rarity.name];
        [query fromLocalDatastore];
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             __block PFObject *pfCardRarity;
             
             if (task.error)
             {
                 return task;
             }
             
             for (PFObject *object in task.result)
             {
                 pfCardRarity = object;
             }
             
             if (pfCardRarity)
             {
                 callbackFindArtist(cardId, pfCardRarity);
             }
             else
             {
                 // not found in local datastore, find remotely
                 card = [DTCard objectForPrimaryKey:cardId];
                 query = [PFQuery queryWithClassName:@"CardRarity"];
                 [query whereKey:@"name" equalTo:card.rarity.name];
                 
                 [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task)
                  {
                      card = [DTCard objectForPrimaryKey:cardId];
                      NSArray *results = task.result;
                      
                      if (results.count > 0)
                      {
                          pfCardRarity = task.result[0];
                      }
                      else
                      {
                          // not found remotely
                          pfCardRarity = [PFObject objectWithClassName:@"CardRarity"];
                          pfCardRarity[@"name"] = card.rarity.name;
                          pfCardRarity[@"symbol"] = card.rarity.symbol;
                      }
                      
                      [pfCardRarity pinInBackgroundWithBlock:^(BOOL success, NSError *error)
                       {
                           callbackFindArtist(cardId, pfCardRarity);
                       }];
                      return task;
                  }];
             }
             
             return task;
         }];
    };
    
    callbackFindCardRarity(cardId);
}

-(void) processQueue
{
    if (_parseQueue.count == 0 || _currentParseQueue)
    {
        return;
    }
    
    _currentParseQueue = [_parseQueue objectAtIndex:0];
    [_parseQueue removeObject:_currentParseQueue];
    [self processCurrentParseQueue];
}

#pragma mark - Parse maintenance
-(void) transferCardsFromSet:(NSString*) sourceSetId toSet:(NSString*) destSetId
{
    __block PFQuery *query = [PFQuery queryWithClassName:@"Set"];
    
    void (^callbackUpdateRating)(PFObject *src, PFObject *dest) = ^void(PFObject *src, PFObject *dest)
    {
        PFQuery *q = [PFQuery queryWithClassName:@"CardRating"];
        [q includeKey:@"card"];
        [q whereKey:@"card" equalTo:src];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
        {
             if (!error)
             {
                 for (PFObject *object in objects)
                 {
                     object[@"card"] = dest;
                     
                     [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                     {
                         if (succeeded)
                         {
#ifdef DEBUG
                             DTCard *card = [[DTCard objectsWithPredicate:[NSPredicate predicateWithFormat:@"name = %@ AND set.code = %@", src[@"name"], src[@"set"][@"code"]]] firstObject];
                             
                             NSLog(@"^Parse CardRating: %@ [%@]", card.name, card.set.code);
#endif
                         }
                     }];
                 }
             }
        }];
    };
    
    void (^callbackTransferCards)(NSArray *pfSource, NSArray *pfDest) = ^void(NSArray *pfSource, NSArray *pfDest)
    {
        for (PFObject *src in pfSource)
        {
            PFObject *target;
            
            for (PFObject *dest in pfDest)
            {
                if ([src[@"name"] isEqualToString:dest[@"name"]] &&
                    [src[@"number"] isEqualToString:dest[@"number"]])
                {
                    target = dest;
                    break;
                }
            }
            
            if (target)
            {
                [target incrementKey:@"numberOfViews" byAmount:src[@"numberOfViews"]];
                [target incrementKey:@"rating" byAmount:src[@"rating"]];
                [target saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                 {
                     if (succeeded)
                     {
#ifdef DEBUG
                         DTCard *card = [[DTCard objectsWithPredicate:[NSPredicate predicateWithFormat:@"name = %@ AND set.code = %@", target[@"name"], target[@"set"][@"code"]]] firstObject];
                         NSLog(@"^Parse: %@ [%@]", card.name, card.set.code);
#endif
                         if (src[@"rating"])
                         {
                             callbackUpdateRating(src, target);
                         }
                     }
                 }];
            }
            else
            {
                DTCard *card = [[DTCard objectsWithPredicate:[NSPredicate predicateWithFormat:@"name = %@ AND set.code = %@", src[@"name"], src[@"set"][@"code"]]] firstObject];
                
                void (^callbackUpdateCard)(PFObject *pfCard) = ^void(PFObject *pfCard)
                {
                    if (src[@"rating"])
                    {
                        callbackUpdateRating(src, pfCard);
                    }
                    
                    _currentParseQueue = nil;
                    [self processQueue];
                };
                
                [_parseQueue addObject:@[card.cardId, callbackUpdateCard]];
                [self processQueue];
            }
        }
    };
    
    [query getObjectInBackgroundWithId:sourceSetId block:^(PFObject *src, NSError *error)
    {
        PFObject *srcSet = src;
        
        query = [PFQuery queryWithClassName:@"Set"];
        [query getObjectInBackgroundWithId:destSetId block:^(PFObject *dest, NSError *error)
        {
            PFObject *destSet = dest;
            
            query = [PFQuery queryWithClassName:@"Card"];
            [query includeKey:@"set"];
            [query whereKey:@"set" equalTo:srcSet];
            [query orderByAscending:@"name"];
            [query findObjectsInBackgroundWithBlock:^(NSArray *srcObjects, NSError *error)
            {
                if (!error)
                {
                    query = [PFQuery queryWithClassName:@"Card"];
                    [query includeKey:@"set"];
                    [query whereKey:@"set" equalTo:destSet];
                    [query orderByAscending:@"name"];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *destObjects, NSError *error)
                    {
                        if (!error)
                        {
                            callbackTransferCards(srcObjects, destObjects);
                        }
                    }];
                }
            }];
        }];
    }];
}

-(void) deleteDuplicateParseCards
{
    PFQuery *query = [PFQuery queryWithClassName:@"Card"];
    [query whereKeyDoesNotExist:@"rarity"];
    [query includeKey:@"set"];
    [query orderByAscending:@"name"];
    
//#if !defined(_OS_IPHONE)
//    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
//#endif
    
    [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
     {
         for (PFObject *pfCard in task.result)
         {
             PFQuery *query2 = [PFQuery queryWithClassName:@"Card"];
             [query2 whereKey:@"set" equalTo:pfCard[@"set"]];
             [query2 whereKey:@"name" equalTo:pfCard[@"name"]];
             
             [[query2 findObjectsInBackground] continueWithBlock:^id(BFTask *task2)
              {
                  for (PFObject *pfCard2 in task2.result)
                  {
                      PFObject* pfSet2 = pfCard2[@"set"];
                      
                      NSLog(@"^Card: (%@)%@ [(%@)%@]", pfCard2.objectId, pfCard2[@"name"], pfSet2.objectId, pfSet2[@"name"]);
                      [pfCard2 incrementKey:@"numberOfViews" byAmount:pfCard[@"numberOfViews"]];
                      if (pfCard[@"rating"])
                      {
                          [pfCard2 incrementKey:@"rating" byAmount:pfCard[@"rating"]];
                      }
                      
                      [pfCard2 saveEventually:^(BOOL success, NSError *error) {
                          PFObject* pfSet = pfCard[@"set"];
                          
                          NSLog(@"-Card: (%@)%@ [(%@)%@]", pfCard.objectId, pfCard[@"name"], pfSet.objectId, pfSet[@"name"]);
                          [pfCard deleteEventually];
                          
//#if !defined(_OS_IPHONE)
//                          dispatch_semaphore_signal(sema);
//#endif
                      }];
                  }
                  
                  return nil;
              }];
         }
         return nil;
     }];
    
//#if !defined(_OS_IPHONE)
//    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
//#endif
}

-(void) updateParseCards
{
    for (DTSet *set in [[DTSet allObjects] sortedResultsUsingProperty:@"name" ascending:YES])
    {
        if ([set.code isEqualToString:@"WWK"] ||
            [set.code isEqualToString:@"ZEN"])
        {
            for (DTCard *card in [[DTCard objectsWithPredicate:[NSPredicate predicateWithFormat:@"set.code = %@", set.code]] sortedResultsUsingProperty:@"name" ascending:YES])
            {
                void (^callbackUpdateCard)(PFObject *pfCard) = ^void(PFObject *pfCard) {
                    // do nothing here...
                    
                    _currentParseQueue = nil;
                    [self processQueue];
                };
                
                [_parseQueue addObject:@[card.cardId, callbackUpdateCard]];
                [self processQueue];

            }
        }
    }
}

-(void) uploadSets
{
    NSMutableArray *arrBlocks = [[NSMutableArray alloc] init];
    NSMutableArray *arrSetTypes = [[NSMutableArray alloc] init];
    
    void (^callbackUploadSets)(NSArray *pfBlocks, NSArray *pfSetTypes) = ^void(NSArray *pfBlocks, NSArray *pfSetTypes) {
        for (DTSet *dt in [[DTSet allObjects] sortedResultsUsingProperty:@"name" ascending:YES])
        {
            PFQuery *query = [PFQuery queryWithClassName:@"Set"];
            [query whereKey:@"name" equalTo:dt.name];
            
            __block NSString *dtId = dt.setId;
            
            [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
            {
                __block PFObject *pfDt;
                __block DTSet *innerDt = [DTSet objectForPrimaryKey:dtId];
                BOOL existing = YES;
                
                if (task.error)
                {
                    return task;
                }
                 
                for (PFObject *object in task.result)
                {
                    pfDt = object;
                }
                 
                if (!pfDt)
                {
                    pfDt = [PFObject objectWithClassName:@"Set"];
                    existing = NO;
                }
                pfDt[@"code"] = innerDt.code;
                if (innerDt.gathererCode.length > 0)
                {
                    pfDt[@"gathererCode"] = innerDt.gathererCode;
                }
                else
                {
                    [pfDt removeObjectForKey:@"gathererCode"];
                }
                if (innerDt.magicCardsInfoCode.length > 0)
                {
                    pfDt[@"magicCardsInfoCode"] = innerDt.magicCardsInfoCode;
                }
                else
                {
                    [pfDt removeObjectForKey:@"magicCardsInfoCode"];
                }
                pfDt[@"name"] = innerDt.name;
                pfDt[@"numberOfCards"] = [NSNumber numberWithInt:innerDt.numberOfCards];
                if (innerDt.oldCode.length > 0)
                {
                    pfDt[@"oldCode"] = innerDt.oldCode;
                }
                else
                {
                    [pfDt removeObjectForKey:@"oldCode"];
                }
                pfDt[@"onlineOnly"] = [NSNumber numberWithBool:innerDt.onlineOnly];
                pfDt[@"releaseDate"] = innerDt.releaseDate;
                if (innerDt.tcgPlayerName.length > 0)
                {
                    pfDt[@"tcgPlayerName"] = innerDt.tcgPlayerName;
                }
                else
                {
                    [pfDt removeObjectForKey:@"tcgPlayerName"];
                }
                for (PFObject *pfBlock in pfBlocks)
                {
                    if ([pfBlock[@"name"] isEqualToString:innerDt.block.name])
                    {
                        pfDt[@"block"] = pfBlock;
                        break;
                    }
                }
                for (PFObject *pfSetType in pfSetTypes)
                {
                    if ([pfSetType[@"name"] isEqualToString:innerDt.type.name])
                    {
                        pfDt[@"type"] = pfSetType;
                        break;
                    }
                }
                 
                [pfDt saveEventually:^(BOOL success, NSError *error) {
                    innerDt = [DTSet objectForPrimaryKey:dtId];
                    NSLog(@"%@Set: %@", (existing ? @"^" : @"+"), innerDt.name);
                }];
                 
                return nil;
            }];
        }
    };
    
    PFQuery *query = [PFQuery queryWithClassName:@"Block"];
    [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
    {
        for (PFObject *object in task.result)
        {
            [arrBlocks addObject:object];
        }
    
        PFQuery *query2 = [PFQuery queryWithClassName:@"SetType"];
        [[query2 findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             for (PFObject *object in task.result)
             {
                 [arrSetTypes addObject:object];
             }
             
             callbackUploadSets(arrBlocks, arrSetTypes);
             return nil;
         }];
        
        return nil;
    }];
}

-(void) uploadArtists
{
    for (DTArtist *dt in [[DTArtist allObjects] sortedResultsUsingProperty:@"name" ascending:YES])
    {
        PFQuery *query = [PFQuery queryWithClassName:@"Artist"];
        [query whereKey:@"name" equalTo:dt.name];
        
        __block NSString *dtId = dt.artistId;
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             __block PFObject *pfDt;
             __block DTArtist *innerDt = [DTArtist objectForPrimaryKey:dtId];
             __block BOOL existing = YES;
             
             if (task.error)
             {
                 return task;
             }
             
             for (PFObject *object in task.result)
             {
                 pfDt = object;
             }
             
             if (!pfDt)
             {
                 pfDt = [PFObject objectWithClassName:@"Artist"];
                 existing = NO;
             }
             pfDt[@"name"] = innerDt.name;
             
             [pfDt saveEventually:^(BOOL success, NSError *error) {
                 innerDt = [DTArtist objectForPrimaryKey:dtId];
                 NSLog(@"%@Artist: %@", existing ? @"^": @"+", innerDt.name);
             }];
             
             return nil;
         }];
    }
}

-(void) uploadBlocks
{
    for (DTBlock *dt in [[DTBlock allObjects] sortedResultsUsingProperty:@"name" ascending:YES])
    {
        PFQuery *query = [PFQuery queryWithClassName:@"Block"];
        [query whereKey:@"name" equalTo:dt.name];
        
        __block NSString *dtId = dt.blockId;
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             __block PFObject *pfDt;
             __block DTBlock *innerDt = [DTBlock objectForPrimaryKey:dtId];
             __block BOOL existing = YES;
             
             if (task.error)
             {
                 return task;
             }
             
             for (PFObject *object in task.result)
             {
                 pfDt = object;
             }
             
             if (!pfDt)
             {
                 pfDt = [PFObject objectWithClassName:@"Block"];
                 existing = NO;
             }
             pfDt[@"name"] = innerDt.name;
             
             [pfDt saveEventually:^(BOOL success, NSError *error) {
                 innerDt = [DTBlock objectForPrimaryKey:dtId];
                 NSLog(@"%@Block: %@", existing ? @"^": @"+", innerDt.name);
             }];
             
             return nil;
         }];
    }
}

-(void) uploadSetTypes
{
    for (DTSetType *dt in [[DTSetType allObjects] sortedResultsUsingProperty:@"name" ascending:YES])
    {
        PFQuery *query = [PFQuery queryWithClassName:@"SetType"];
        [query whereKey:@"name" equalTo:dt.name];
        
        __block NSString *dtId = dt.setTypeId;
        
        [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
         {
             __block PFObject *pfDt;
             __block DTSetType *innerDt = [DTSetType objectForPrimaryKey:dtId];
             __block BOOL existing = YES;
             
             if (task.error)
             {
                 return task;
             }
             
             for (PFObject *object in task.result)
             {
                 pfDt = object;
             }
             
             if (!pfDt)
             {
                 pfDt = [PFObject objectWithClassName:@"SetType"];
                 existing = NO;
             }
             pfDt[@"name"] = innerDt.name;
             
             [pfDt saveEventually:^(BOOL success, NSError *error) {
                 innerDt = [DTSetType objectForPrimaryKey:dtId];
                 NSLog(@"%@SetType: %@", existing ? @"^": @"+", innerDt.name);
             }];
             
             return nil;
         }];
    }
}

#pragma mark - Unused
-(void) mergeLocalUserManaWithRemote:(PFObject*) remoteUserMana
{
    __block PFQuery *query = [PFQuery queryWithClassName:@"UserMana"];
    [query fromLocalDatastore];
    
    [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task)
     {
         PFObject *localUserMana;
         
         if (task.error)
         {
             return task;
         }
         
         for (PFObject *object in task.result)
         {
             localUserMana = object;
         }
         
         if (localUserMana)
         {
             if (remoteUserMana)
             {
                 remoteUserMana[@"black"] = @([remoteUserMana[@"black"] integerValue] + [localUserMana[@"black"] integerValue]);
                 remoteUserMana[@"blue"] = @([remoteUserMana[@"blue"] integerValue] + [localUserMana[@"blue"] integerValue]);
                 remoteUserMana[@"green"] = @([remoteUserMana[@"green"] integerValue] + [localUserMana[@"green"] integerValue]);
                 remoteUserMana[@"red"] = @([remoteUserMana[@"red"] integerValue] + [localUserMana[@"red"] integerValue]);
                 remoteUserMana[@"white"] = @([remoteUserMana[@"white"] integerValue] + [localUserMana[@"white"] integerValue]);
                 remoteUserMana[@"colorless"] = @([remoteUserMana[@"colorless"] integerValue] + [localUserMana[@"colorless"] integerValue]);
                 remoteUserMana[@"totalCMC"] = @([remoteUserMana[@"black"] integerValue] +
                 [remoteUserMana[@"blue"] integerValue] +
                 [remoteUserMana[@"green"] integerValue] +
                 [remoteUserMana[@"red"] integerValue] +
                 [remoteUserMana[@"white"] integerValue] +
                 [remoteUserMana[@"colorless"] integerValue]);
                 [self saveUserMana:remoteUserMana];
             }
             else
             {
                 [self saveUserMana:localUserMana];
             }
         }
         else
         {
             if (remoteUserMana)
             {
                 [[NSNotificationCenter defaultCenter] postNotificationName:kParseUserManaDone
                                                                     object:nil
                                                                   userInfo:@{@"userMana": remoteUserMana}];
             }
             else
             {
                 // not found in local store, create new one
                 localUserMana = [PFObject objectWithClassName:@"UserMana"];
                 localUserMana[@"black"]     = @0;
                 localUserMana[@"blue"]      = @0;
                 localUserMana[@"green"]     = @0;
                 localUserMana[@"red"]       = @0;
                 localUserMana[@"white"]     = @0;
                 localUserMana[@"colorless"] = @0;
                 localUserMana[@"totalCMC"]  = @0;
                 
                 [localUserMana pinInBackgroundWithBlock:^void(BOOL succeeded, NSError *error) {
                     [[NSNotificationCenter defaultCenter] postNotificationName:kParseUserManaDone
                                                                         object:nil
                                                                       userInfo:@{@"userMana": localUserMana}];
                 }];
             }
             
         }
         
         return task;
     }];
}
@end
