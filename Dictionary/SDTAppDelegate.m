//
//  AppDelegate.m
//  Dictionary
//
//  Created by Feng Ye on 11/18/11.
//  Copyright (c) 2011 @forresty. All rights reserved.
//

#import "SDTAppDelegate.h"
#import "SDTMainViewController.h"
#import "SDTDictionary.h"
#import "Flurry.h"

@implementation SDTAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [Flurry startSession:@"29W38MKGVJXS7Y92C4ZX"];

  [self copyCacheIfNeeded];

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

  self.window.rootViewController = [[SDTMainViewController alloc] init];

  self.window.backgroundColor = [UIColor whiteColor];

  [self.window makeKeyAndVisible];

  return YES;
}


- (void)copyCacheIfNeeded {
  SDTDictionary *dictionary = [SDTDictionary sharedInstance];

  NSString *bundleValidTermsCacheFilePath = [[NSBundle mainBundle] pathForResource:@"validTerms" ofType:@"txt"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:dictionary.validTermsCacheFilePath]) {
    NSLog(@"copying valid terms from bundle");
    [[NSFileManager defaultManager] copyItemAtPath:bundleValidTermsCacheFilePath toPath:dictionary.validTermsCacheFilePath error:nil];
    [dictionary reloadValidTermsCache];
  }

  NSString *bundleInvalidTermsCacheFilePath = [[NSBundle mainBundle] pathForResource:@"invalidTerms" ofType:@"txt"];

  if (![[NSFileManager defaultManager] fileExistsAtPath:dictionary.invalidTermsCacheFilePath]) {
    NSLog(@"copying invalid terms from bundle");
    [[NSFileManager defaultManager] copyItemAtPath:bundleInvalidTermsCacheFilePath toPath:dictionary.invalidTermsCacheFilePath error:nil];
    [dictionary reloadInvalidTermsCache];
  }
}


@end
