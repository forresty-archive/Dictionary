//
//  LookupResponse.m
//  Dictionary
//
//  Created by Forrest Ye on 7/1/13.
//
//

#import "LookupResponse.h"

@implementation LookupResponse

+ (LookupResponse *)responseWithProgressState:(DictionaryLookupProgressState)state terms:(NSArray *)terms {
  LookupResponse *response = [[self alloc] init];
  response.lookupState = state;
  response.terms = [terms sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    return [obj1 caseInsensitiveCompare:obj2];
  }];

  return response;
}

@end
