//
//  Dictionary.m
//  Dictionary
//
//  Created by Forrest Ye on 6/24/13.
//
//

#import "SDTDictionary.h"
#import "UIKit/UITextChecker.h"
#import "UIKit/UIReferenceLibraryViewController.h"
#import "SVProgressHUD.h"

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
  // read file line by line using C is roughly 1 time slower, but does not have memory usage spike... hmm.
  // since the spike is only 5~10 MB so I think generally it is acceptable to just use the obj-c way and try not to over-optimize here

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


@interface SDTDictionary ()

@property UITextChecker *textChecker;

@property (readonly) NSString *cacheDirectoryPath;

@end


@implementation SDTDictionary


# pragma mark - object life cycle


+ (instancetype)sharedInstance {
  static SDTDictionary *_instance = nil;

  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _instance = [[SDTDictionary alloc] init];
  });

  return _instance;
}


- (instancetype)init {
  self = [super init];

  [self reloadCacheIfNeeded];

  _textChecker = [[UITextChecker alloc] init];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCache) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreCacheDueToMemoryWarningHandlingIfNeeded) name:UIApplicationDidBecomeActiveNotification object:nil];

  return self;
}


# pragma mark - handling memory warnings


- (void)handleMemoryWarning {
  NSLog(@"memory warning received");
  // only discard if the app is in the background
  if ([UIApplication sharedApplication].applicationState  == UIApplicationStateBackground) {
    [self discardCache];
  }
}


- (void)discardCache {
  NSLog(@"discarding cache");
  self.validTermsCache = nil;
  self.invalidTermsCache = nil;
}


- (void)restoreCacheDueToMemoryWarningHandlingIfNeeded {
  if (!self.validTermsCache || !self.invalidTermsCacheFilePath) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    }];

    NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
    [backgroundQueue addOperationWithBlock:^{
      [self reloadCacheIfNeeded];

      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [SVProgressHUD dismiss];
      }];
    }];
  }
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
  NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];

  [backgroundQueue addOperationWithBlock:^{
    @autoreleasepool {
      [self.validTermsCache writeAsTXTToFile:self.validTermsCacheFilePath];
      NSLog(@"%d valid terms written", self.validTermsCache.count);
    }

    @autoreleasepool {
      [self.invalidTermsCache writeAsTXTToFile:self.invalidTermsCacheFilePath];
      NSLog(@"%d invalid terms written", self.invalidTermsCache.count);
    }

    // test if memory warning handling is working
//    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];

    // be a nice citizen, discard cache in the background and minimize memory footprint
    [self discardCache];
  }];
}


- (NSString *)validTermsCacheFilePath {
  return [self.cacheDirectoryPath stringByAppendingPathComponent:@"validTerms.txt"];
}


- (NSString *)invalidTermsCacheFilePath {
  return [self.cacheDirectoryPath stringByAppendingPathComponent:@"invalidTerms.txt"];
}


- (NSString *)cacheDirectoryPath {
  return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
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
