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


@implementation Dictionary {

@private

  __strong NSMutableSet *validTermsCache;

  __strong UITextChecker *__textChecker;
}


# pragma mark - object life cycle


+(instancetype)sharedInstance {
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


@end
