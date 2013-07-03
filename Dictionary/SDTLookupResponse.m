//
//  LookupResponse.m
//  Dictionary
//
//  Created by Forrest Ye on 7/1/13.
//
//

#import "SDTLookupResponse.h"

@implementation SDTLookupResponse

+ (SDTLookupResponse *)responseWithProgressState:(DictionaryLookupProgressState)state terms:(NSArray *)terms {
  SDTLookupResponse *response = [[self alloc] init];
  response.lookupState = state;
  response.terms = [[[NSSet setWithArray:terms] allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    return [obj1 caseInsensitiveCompare:obj2];
  }];

  return response;
}

@end
