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
#import "SDTDictionaryViewDefinitions.h"
#import "Flurry.h"

@implementation SDTAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  [Flurry startSession:@"29W38MKGVJXS7Y92C4ZX"];

  [self copyCacheIfNeeded];

  [self setupUIAppearances];

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


- (void)setupUIAppearances {
  [[UISearchBar appearance] setTintColor:DICTIONARY_BASIC_TINT_COLOR];

  // http://stackoverflow.com/questions/11572372/modifying-uisearchbar-cancel-button-font-text-color-and-style
  NSDictionary *attributes = @{ UITextAttributeTextColor: DICTIONARY_BASIC_TEXT_COLOR,
                                UITextAttributeTextShadowColor: DICTIONARY_BASIC_TINT_COLOR,
                                UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)] };
  [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:attributes forState:UIControlStateNormal];

  UITableViewHeaderFooterView *headerViewProxy = [UITableViewHeaderFooterView appearance];
  headerViewProxy.tintColor = DICTIONARY_BASIC_TEXT_COLOR;

  UILabel *labelProxy = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil];
  labelProxy.textColor = DICTIONARY_BASIC_TINT_COLOR;
  labelProxy.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
  labelProxy.shadowOffset = CGSizeZero;
}


@end
