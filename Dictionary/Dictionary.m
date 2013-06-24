//
//  Dictionary.m
//  Dictionary
//
//  Created by Forrest Ye on 6/24/13.
//
//

#import "Dictionary.h"
#import "UIKit/UITextChecker.h"
#import "UIKit/UIReferenceLibraryViewController.h"


static NSString *kDictionaryLookupHistory = @"kDictionaryLookupHistory";
static int kDictionaryLookupHistoryLimit = 15;


@implementation Dictionary {

@private

  __strong NSMutableSet *validTermsCache;

  __strong UITextChecker *__textChecker;
}


# pragma mark - object life cycle


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

  __textChecker = [[UITextChecker alloc] init];

  return self;
}


# pragma mark - definition / completion lookup && guesses


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
  return [__textChecker guessesForWordRange:NSMakeRange(0, [term length]) inString:term language:@"en_US"];
}


-(NSArray *)completionsForTerm:(NSString *)term {
  return [__textChecker completionsForPartialWordRange:NSMakeRange(0, [term length]) inString:term language:@"en_US"];
}


# pragma mark - history management


-(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  return [defaults objectForKey:kDictionaryLookupHistory];
}


-(void)setLookupHistory:(NSArray *)lookupHistory {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:lookupHistory forKey:kDictionaryLookupHistory];
  [defaults synchronize];
}


-(void)addLookupHistoryWithTerm:(NSString *)term {
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
