//
//  Dictionary.m
//  Dictionary
//
//  Created by Forrest Ye on 6/24/13.
//
//

#import "Dictionary.h"


static NSString *kDictionaryLookupHistory = @"kDictionaryLookupHistory";
static int kDictionaryLookupHistoryLimit = 15;


@implementation Dictionary {
@private
  __strong NSMutableSet *validTermsCache;
}


+(instancetype)sharedDictionary {
  static Dictionary *_instance = nil;

  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _instance = [[Dictionary alloc] init];
  });

  return _instance;
}


-(instancetype)init {
  self = [super init];

  validTermsCache = [[NSMutableSet alloc] init];

  return self;
}


-(BOOL)hasDefinitionForTerm:(NSString *)term {
  if ([validTermsCache containsObject:term]) {
    return YES;
  }

  BOOL hasDefinition = [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:term];

  if (hasDefinition) {
    [validTermsCache addObject:term];
  }

  return hasDefinition;
}


-(NSArray *)guessesForTerm:(NSString *)term {
  return @[];
}


-(NSArray *)completionsForTerm:(NSString *)term {
  return @[];
}


# pragma mark - lookup history management


-(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  return [defaults objectForKey:kDictionaryLookupHistory];
}


-(void)setLookupHistory:(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:lookupHistory forKey:kDictionaryLookupHistory];
  [defaults synchronize];
}


-(void)addToLookupHistory:(NSString *)term {
  NSMutableArray *lookupHistory = [@[term] mutableCopy];

  for (NSString *termInHistory in [self lookupHistory]) {
    if (![term isEqual:termInHistory] && [lookupHistory count] < kDictionaryLookupHistoryLimit) {
      [lookupHistory addObject:termInHistory];
    }
  }

  [self setLookupHistory:lookupHistory];
}


-(void)clearLookupHistory {
  [self setLookupHistory:@[]];
}


@end
