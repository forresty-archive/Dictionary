//
//  LookupHistory.m
//  Dictionary
//
//  Created by Forrest Ye on 6/25/13.
//
//

#import "LookupHistory.h"


static NSString *kDictionaryLookupHistory = @"kDictionaryLookupHistory";
static int kDictionaryLookupHistoryLimit = 15;


@implementation LookupHistory


# pragma mark - object life cycle


+ (instancetype)sharedInstance {
  static LookupHistory *_instance = nil;

  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _instance = [[LookupHistory alloc] init];
  });

  return _instance;
}


# pragma mark - history management


- (NSArray *)recent {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  return [defaults objectForKey:kDictionaryLookupHistory];
}


- (void)setLookupHistory:(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:lookupHistory forKey:kDictionaryLookupHistory];
  [defaults synchronize];
}


- (void)addLookupHistoryWithTerm:(NSString *)term {
  NSMutableArray *lookupHistory = [@[term] mutableCopy];

  for (NSString *termInHistory in [self recent]) {
    if (![term isEqual:termInHistory] && [lookupHistory count] < kDictionaryLookupHistoryLimit) {
      [lookupHistory addObject:termInHistory];
    }
  }

  [self setLookupHistory:lookupHistory];
}


- (void)clear {
  [self setLookupHistory:@[]];
}


- (NSUInteger)count {
  return [[self recent] count];
}


# pragma mark - object subscripting


- (NSString *)objectAtIndexedSubscript:(NSUInteger)idx {
  return [self recent][idx];
}


@end
