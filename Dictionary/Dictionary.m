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

@interface Dictionary ()

//@property NSMutableSet *validTermsCache;
@property UITextChecker *textChecker;

@end


@implementation Dictionary


# pragma mark - object life cycle


+ (instancetype)sharedInstance {
  static Dictionary *_instance = nil;

  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _instance = [[Dictionary alloc] init];
  });

  return _instance;
}


- (instancetype)init {
  self = [super init];

//  _validTermsCache = [[NSMutableSet alloc] init];
  [self reloadCache];

  _textChecker = [[UITextChecker alloc] init];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCache) name:UIApplicationDidEnterBackgroundNotification object:nil];

  return self;
}

- (void)reloadCache {
  _validTermsCache = [NSMutableSet setWithArray:[NSArray arrayWithContentsOfFile:[self cacheFilePath]]];
  NSLog(@"%d terms read", self.validTermsCache.count);
}

- (void)saveCache {
  NSMutableArray *array = [@[] mutableCopy];
  for (NSString *term in self.validTermsCache) {
    [array addObject:term];
  }

  [array writeToFile:[self cacheFilePath] atomically:YES];
  NSLog(@"%d terms written", array.count);
}


- (NSString *)cacheFilePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];

  return [documentsDirectory stringByAppendingPathComponent:@"validTerms.txt"];
}


# pragma mark - definition / completion lookup && guesses


- (BOOL)hasDefinitionForTerm:(NSString *)term {
  if ([self.validTermsCache containsObject:term]) {
    return YES;
  }

  BOOL hasDefinition = [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:term];

  if (hasDefinition) {
    [self.validTermsCache addObject:term];
  }

  return hasDefinition;
}


- (NSArray *)guessesForTerm:(NSString *)term {
  return [self.textChecker guessesForWordRange:NSMakeRange(0, [term length]) inString:term language:@"en_US"];
}


- (NSArray *)completionsForTerm:(NSString *)term {
  return [self.textChecker completionsForPartialWordRange:NSMakeRange(0, [term length]) inString:term language:@"en_US"];
}


@end
