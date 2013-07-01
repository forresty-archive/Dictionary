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
#import "Flurry.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [Flurry startSession:@"29W38MKGVJXS7Y92C4ZX"];

  [self copyCacheIfNeeded];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  self.window.rootViewController = [[MainViewController alloc] init];

  self.window.backgroundColor = [UIColor whiteColor];

  [self.window makeKeyAndVisible];

  return YES;
}


- (void)copyCacheIfNeeded {
  BOOL needReload = NO;

  NSString *bundleValidTermsCacheFilePath = [[NSBundle mainBundle] pathForResource:@"validTerms" ofType:@"txt"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:[[Dictionary sharedInstance] validTermsCacheFilePath]]) {
    [[NSFileManager defaultManager] copyItemAtPath:bundleValidTermsCacheFilePath toPath:[[Dictionary sharedInstance] validTermsCacheFilePath] error:nil];
    needReload = YES;
  }

  NSString *bundleInvalidTermsCacheFilePath = [[NSBundle mainBundle] pathForResource:@"invalidTerms" ofType:@"txt"];

  if (![[NSFileManager defaultManager] fileExistsAtPath:[[Dictionary sharedInstance] invalidTermsCacheFilePath]]) {
    [[NSFileManager defaultManager] copyItemAtPath:bundleInvalidTermsCacheFilePath toPath:[[Dictionary sharedInstance] invalidTermsCacheFilePath] error:nil];
    needReload = YES;
  }

  if (needReload) {
    [[Dictionary sharedInstance] reloadCache];
  }
}


@end
