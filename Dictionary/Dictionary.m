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

@property NSMutableSet *validTermsCache;
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

  _validTermsCache = [[NSMutableSet alloc] init];

  _textChecker = [[UITextChecker alloc] init];

  return self;
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
