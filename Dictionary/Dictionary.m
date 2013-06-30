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


# pragma mark - NSArray WriteAsTXT addition


@interface NSArray (ReadWriteAsTXT)

- (void)writeAsTXTToFile:(NSString *)path;

+ (NSArray *)arrayWithTXTContentsOfFile:(NSString *)path;

@end


@implementation NSArray (ReadWriteAsTXT)

- (void)writeAsTXTToFile:(NSString *)path {
  NSMutableString *result = [@"" mutableCopy];

  for (NSString *term in self) {
    [result appendString:term];
    [result appendString:@"\n"];
  }

  [result writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (NSArray *)arrayWithTXTContentsOfFile:(NSString *)path {
  NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

  return [fileContent componentsSeparatedByString:@"\n"];
}

@end


# pragma mark - Dictionary implementation


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


# pragma mark - cache manipulation


- (void)reloadCache {
  _validTermsCache = [NSMutableSet setWithArray:[NSArray arrayWithTXTContentsOfFile:[self validTermsCacheFilePath]]];
  NSLog(@"%d valid terms read", self.validTermsCache.count);

  _invalidTermsCache = [NSMutableSet setWithArray:[NSArray arrayWithTXTContentsOfFile:[self invalidTermsCacheFilePath]]];
  NSLog(@"%d invalid terms read", self.invalidTermsCache.count);
}


- (void)saveCache {
  NSMutableArray *array = [@[] mutableCopy];
  for (NSString *term in self.validTermsCache) {
    [array addObject:term];
  }

//  [array writeToFile:[self validTermsCacheFilePath] atomically:YES];
  [array writeAsTXTToFile:[self validTermsCacheFilePath]];
  NSLog(@"%d valid terms written", array.count);

  array = [@[] mutableCopy];
  for (NSString *term in self.invalidTermsCache) {
    [array addObject:term];
  }

//  [array writeToFile:[self invalidTermsCacheFilePath] atomically:YES];
  [array writeAsTXTToFile:[self invalidTermsCacheFilePath]];
  NSLog(@"%d invalid terms written", array.count);
}


- (NSString *)validTermsCacheFilePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *cacheDirectory = [paths objectAtIndex:0];

  return [cacheDirectory stringByAppendingPathComponent:@"validTerms.txt"];
}


- (NSString *)invalidTermsCacheFilePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *cacheDirectory = [paths objectAtIndex:0];

  return [cacheDirectory stringByAppendingPathComponent:@"invalidTerms.txt"];
}

# pragma mark - definition / completion lookup && guesses


- (BOOL)hasDefinitionForTerm:(NSString *)term {
  if ([self.validTermsCache containsObject:term]) {
    return YES;
  }

  if ([self.invalidTermsCache containsObject:term]) {
    return NO;
  }

  BOOL hasDefinition = [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:term];

  if (hasDefinition) {
    [self.validTermsCache addObject:term];
  } else {
    [self.invalidTermsCache addObject:term];
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
