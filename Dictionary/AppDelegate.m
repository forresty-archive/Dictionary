//
//  AppDelegate.m
//  Dictionary
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 @forresty. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "Dictionary.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [self copyCacheIfNeeded];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  self.window.rootViewController = [[MainViewController alloc] init];

  self.window.backgroundColor = [UIColor whiteColor];

  [self.window makeKeyAndVisible];

  return YES;
}


- (void)copyCacheIfNeeded {
  NSString *bundleValidTermsCacheFilePath = [[NSBundle mainBundle] pathForResource:@"validTerms" ofType:@"txt"];

  if (![[NSFileManager defaultManager] fileExistsAtPath:[[Dictionary sharedInstance] validTermsCacheFilePath]]) {
    // cache file not exist, copy from bundle
    [[NSFileManager defaultManager] copyItemAtPath:bundleValidTermsCacheFilePath toPath:[[Dictionary sharedInstance] validTermsCacheFilePath] error:nil];
    [[Dictionary sharedInstance] reloadCache];
  }

  NSString *bundleInvalidTermsCacheFilePath = [[NSBundle mainBundle] pathForResource:@"invalidTerms" ofType:@"txt"];

  if (![[NSFileManager defaultManager] fileExistsAtPath:[[Dictionary sharedInstance] invalidTermsCacheFilePath]]) {
    // cache file not exist, copy from bundle
    [[NSFileManager defaultManager] copyItemAtPath:bundleInvalidTermsCacheFilePath toPath:[[Dictionary sharedInstance] invalidTermsCacheFilePath] error:nil];
    [[Dictionary sharedInstance] reloadCache];
  }
}


@end
