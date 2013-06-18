//
//  DICAppDelegate.m
//  Dictionary
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 @forresty. All rights reserved.
//

#import "DICAppDelegate.h"
#import "DICWordLookupTableViewController.h"
#import "MKiCloudSync.h"

@implementation DICAppDelegate

@synthesize window = _window;

DICWordLookupTableViewController *wordLookupController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [MKiCloudSync start];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  wordLookupController = [[DICWordLookupTableViewController alloc] init];

  [self.window addSubview:wordLookupController.view];

  self.window.backgroundColor = [UIColor whiteColor];
  [self.window makeKeyAndVisible];

  return YES;
}

@end
