//
//  AppDelegate.m
//  DeckTracker
//
//  Created by Jovit Royeca on 8/2/14.
//  Copyright (c) 2014 Jovito Royeca. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "Appirater.h"
#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import "JJJUtils/JJJ.h"


//#import "Decktracker-Swift.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    // Fabric / Crashlytics
    [Fabric with:@[[Crashlytics class]]];

    // FileSystem
//    [[FileManager sharedInstance] moveFilesInDocumentsToCaches];
//    for (NSInteger i=FileSystemLocal; i<=FileSystemOneDrive; i++)
//    {
//        [[FileManager sharedInstance] setupFilesystem:i];
//        [[FileManager sharedInstance] initFilesystem:i];
//    }
//    [[FileManager sharedInstance] syncFiles];

    // Database and Parse
//    [[Database sharedInstance] setupParse:launchOptions];
//    [[Database sharedInstance] setupDb];

    // custom colors
    [[UINavigationBar appearance] setBarTintColor:[JJJUtil colorFromRGB:0x691F01]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
        NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [[UITabBar appearance] setBarTintColor:[JJJUtil  colorFromRGB:0x691F01]];
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    [[UISearchBar appearance] setTintColor:[JJJUtil  colorFromRGB:0x691F01]];
    [[UISegmentedControl appearance] setTintColor:[UIColor grayColor]];
    
    // remove the "Back" title in  back buttons
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
    
    UIViewController *viewController;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone ||
        [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
//        viewController = [[MainViewController alloc] init];
    }
    
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];
    
    [Appirater setAppId:kAppID];
    [Appirater setDaysUntilPrompt:7];
    [Appirater setUsesUntilPrompt:5];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater setDebug:NO];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
//    [FBAppEvents activateApp];
//    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
//    [[Database sharedInstance] closeDb];
//    [[PFFacebookUtils session] close];
}

// Dropbox handler after authenticating
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
  sourceApplication:(NSString *)source
         annotation:(id)annotation
{
    // attempt to extract a token from the url
//    return [FBAppCall handleOpenURL:url
//                  sourceApplication:source
//                        withSession:[PFFacebookUtils session]];
    return YES;
}

@end
