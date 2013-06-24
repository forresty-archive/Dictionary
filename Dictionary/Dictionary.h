//
//  Dictionary.h
//  Dictionary
//
//  Created by Forrest Ye on 6/24/13.
//
//

#import <Foundation/Foundation.h>


@interface Dictionary : NSObject


# pragma mark - object life cycle


+(instancetype)sharedDictionary;


# pragma mark - look up


-(BOOL)hasDefinitionForTerm:(NSString *)term;


-(NSArray *)guessesForTerm:(NSString *)term;


-(NSArray *)completionsForTerm:(NSString *)term;


# pragma mark - history management


-(NSArray *)lookupHistory;


-(void)clearLookupHistory;


-(void)addLookupHistoryWithTerm:(NSString *)term;


@end
