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

//#include <stdio.h>

# pragma mark - NSMutableSet ReadWriteAsTXT addition


@interface NSMutableSet (ReadWriteAsTXT)

- (void)writeAsTXTToFile:(NSString *)path;

+ (NSMutableSet *)setWithTXTContentsOfFile:(NSString *)path;

@end


@implementation NSMutableSet (ReadWriteAsTXT)


- (void)writeAsTXTToFile:(NSString *)path {
  NSMutableString *result = [@"" mutableCopy];

  for (NSString *term in self) {
    [result appendString:term];
    [result appendString:@"\n"];
  }

  [result writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}


+ (NSMutableSet *)setWithTXTContentsOfFile:(NSString *)path {
  // read file line by line is roughly 1 time slower, but uses less memory... hmm.

//  NSMutableSet *result = [NSMutableSet set];
//
//  FILE *file = fopen([path UTF8String], "r");
//
//  if (file) {
//    while(!feof(file)) {
//      char *line = NULL;
//      size_t linecap = 0;
//      ssize_t linelen;
//      while ((linelen = getline(&line, &linecap, file)) > 0) {
//        [result addObject:[NSString stringWithCString:line encoding:NSUTF8StringEncoding]];
//      }
//    }
//  }
//
//  fclose(file);
//
//  return result;

  return [self setWithArray:[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"]];
}


@end


# pragma mark - Dictionary


@interface Dictionary ()

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

  [self reloadCacheIfNeeded];

  _textChecker = [[UITextChecker alloc] init];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCache) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discardCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCacheDueToMemoryWarningIfNeeded) name:UIApplicationDidBecomeActiveNotification object:nil];

  return self;
}


# pragma mark - handling memory warnings


- (void)discardCache {
  NSLog(@"memory warning received");
  // only discard if the app is in the background
  if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
    self.validTermsCache = nil;
    self.invalidTermsCache = nil;
  }
}

- (void)reloadCacheDueToMemoryWarningIfNeeded {
  if (!self.validTermsCache || !self.invalidTermsCacheFilePath) {
    [self didStartReloadingCacheDueToMemoryWarning];
    [self reloadCacheIfNeeded];
    [self didEndReloadingCacheDueToMemoryWarning];
  }
}


- (void)didStartReloadingCacheDueToMemoryWarning {
  // show hud
}


- (void)didEndReloadingCacheDueToMemoryWarning {
  // hide hud
}


# pragma mark - cache manipulation


- (void)reloadValidTermsCache {
  @autoreleasepool {
    _validTermsCache = [NSMutableSet setWithTXTContentsOfFile:self.validTermsCacheFilePath];
    NSLog(@"%d valid terms read", self.validTermsCache.count);
  }
}


- (void)reloadInvalidTermsCache {
  @autoreleasepool {
    _invalidTermsCache = [NSMutableSet setWithTXTContentsOfFile:self.invalidTermsCacheFilePath];
    NSLog(@"%d invalid terms read", self.invalidTermsCache.count);
  }
}


- (void)reloadCacheIfNeeded {
  NSLog(@"checking cache status");

  if (!self.validTermsCache) {
    NSLog(@"valid terms cache gone, need reloading");
    [self reloadValidTermsCache];
  }

  if (!self.invalidTermsCache) {
    NSLog(@"invalid terms cache gone, need reloading");
    [self reloadInvalidTermsCache];
  }
}


- (void)saveCache {
  @autoreleasepool {
    [self.validTermsCache writeAsTXTToFile:self.validTermsCacheFilePath];
    NSLog(@"%d valid terms written", self.validTermsCache.count);
  }

  @autoreleasepool {
    [self.invalidTermsCache writeAsTXTToFile:self.invalidTermsCacheFilePath];
    NSLog(@"%d invalid terms written", self.invalidTermsCache.count);
  }
}


- (NSString *)validTermsCacheFilePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

  return [paths[0] stringByAppendingPathComponent:@"validTerms.txt"];
}


- (NSString *)invalidTermsCacheFilePath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

  return [paths[0] stringByAppendingPathComponent:@"invalidTerms.txt"];
}


# pragma mark - definition / completion lookup && guesses


- (BOOL)hasDefinitionForTerm:(NSString *)term {
  NSString *lowercaseTerm = [term lowercaseString];

  if ([self.validTermsCache containsObject:lowercaseTerm]) {
    return YES;
  }

  if ([self.invalidTermsCache containsObject:lowercaseTerm]) {
    return NO;
  }

  BOOL hasDefinition = [UIReferenceLibraryViewController dictionaryHasDefinitionForTerm:lowercaseTerm];

  if (hasDefinition) {
    [self.validTermsCache addObject:lowercaseTerm];
  } else {
    [self.invalidTermsCache addObject:lowercaseTerm];
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
