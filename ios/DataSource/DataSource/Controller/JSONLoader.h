//
//  JSONLoader.h
//  DataSource
//
//  Created by Jovit Royeca on 8/2/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

@import Foundation;

@interface JSONLoader : NSObject

-(void) parseCards1stPass;
-(void) parseCards2ndPass;
-(void) updateTCGSetNames;
-(void) fetchTcgPrices;

@end