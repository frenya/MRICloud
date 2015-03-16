//
//  AppDelegate.m
//  MRICloud
//
//  Created by Frantisek Vymazal on 16/03/15.
//  Copyright (c) 2015 F8.cz. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "MasterViewController.h"

#import "CoreData+MagicalRecord.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Init core data stack
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
    [self iCloudCoreDataSetup];
    
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;

    UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
    MasterViewController *controller = (MasterViewController *)masterNavigationController.topViewController;
    controller.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    return YES;
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Core Data in iCloud

- (void)iCloudCoreDataSetup {
    
    // containerID should contain the same string as your iCloud entitlements
    NSString *containerID = [NSString stringWithFormat:@"iCloud.%@", [[NSBundle mainBundle] bundleIdentifier]];
    
    [MagicalRecord setupCoreDataStackWithiCloudContainer:containerID
                                          contentNameKey:@"MRICloud"                // Must not contain dots
                                         localStoreNamed:@"MRICloud.sqlite"
                                 cloudStorePathComponent:@"Documents/CloudLogs"     // Subpath within your ubiquitous container that will contain db change logs
                                              completion:^{
                                                  // This gets executed after all the setup steps are performed
                                                  // Uncomment the following lines to verify
                                                  NSLog(@"%@", [MagicalRecord currentStack]);
                                                  // NSLog(@"%i events", [Event countOfEntities]);
                                              }];
    
    // NOTE: MagicalRecord's setup is asynchronous, so at this point the default persistent store is still probably NIL!
    // Uncomment the following line if you want to check it.
    // NSLog(@"%@", [MagicalRecord currentStack]);
    
    // The persistent store COORDINATOR is however fully setup and can be accessed
    // Uncomment the following line if you want to check it.
    // NSLog(@"Store coordinator at this point %@", [NSPersistentStoreCoordinator MR_defaultStoreCoordinator]);
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Finally, store change notifications must be observed. Without these, your app will NOT function properly!
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // This notification is issued only once when
    // 1) you run your app on a particular device for the first time
    // 2) you disable/enable iCloud document storage on a particular device
    // usually a couple of seconds after the respective event.
    // The notification must be handled on the MAIN thread and synchronously
    // (because as soon as it finishes, the persistent store is removed by OS).
    // Refer to Apple's documentation for further details
    [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                                      object:[NSPersistentStoreCoordinator MR_defaultStoreCoordinator]
     // queue:nil    // Run on the posting (i.e. background) thread
                                                       queue:[NSOperationQueue mainQueue]   // Run on the main thread
                                                  usingBlock:^(NSNotification *note) {
                                                      // For debugging only
                                                      NSLog(@"%s notificationBlockWillChange:%@, isMainThread = %i", __PRETTY_FUNCTION__, note, [NSThread isMainThread]);
                                                      
                                                      // Disable user interface with setEnabled: or an overlay
                                                      // NOTE: Probably not crucial since the store switch is almost instantaneous.
                                                      //       I only hint it here by changing the tint color to red.
                                                      self.window.tintColor = [UIColor redColor];
                                                      
                                                      // Save changes to current MOC and reset it
                                                      if ([[NSManagedObjectContext MR_defaultContext] hasChanges]) {
                                                          [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
                                                      }
                                                      [[NSManagedObjectContext MR_defaultContext] reset];
                                                      
                                                      // TODO: Drop any managed object references here
                                                  }];
    
    // This notification is issued couple of times every time your app starts
    // The notification must be handled on the BACKGROUND thread and asynchronously to prevent deadlock
    // Refer to Apple's documentation for further details
    [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                                      object:[NSPersistentStoreCoordinator MR_defaultStoreCoordinator]
                                                       queue:nil    // Run on the posting (i.e. background) thread
                                                  usingBlock:^(NSNotification *note) {
                                                      // For debugging only
                                                      NSLog(@"%s notificationBlockDidChange:%@, isMainThread = %i", __PRETTY_FUNCTION__, note, [NSThread isMainThread]);
                                                      
                                                      // This block of code must be executed asynchronously on the main thread!
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          // Recommended by Apple
                                                          [[NSManagedObjectContext MR_defaultContext] reset];
                                                          
                                                          // Notify UI that the data has changes
                                                          // NOTE: I am using the same notification that MagicalRecord sends after merging changes
                                                          [[NSNotificationCenter defaultCenter] postNotificationName:kMagicalRecordPSCDidCompleteiCloudSetupNotification object:nil];
                                                          
                                                          // Re-enable user interface with setEnabled: or removing the overlay
                                                          // NOTE: Probably not crucial since the store switch is almost instantaneous.
                                                          //       I only hint it here by changing the tint color back to default.
                                                          self.window.tintColor = nil;
                                                      });
                                                  }];
    
}


@end
