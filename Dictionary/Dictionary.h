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


+ (instancetype)sharedInstance;


# pragma mark - look up


- (BOOL)hasDefinitionForTerm:(NSString *)term;

- (NSArray *)guessesForTerm:(NSString *)term;

- (NSArray *)completionsForTerm:(NSString *)term;


# pragma mark - cache

@property (nonatomic) NSMutableSet *validTermsCache;

@property (nonatomic) NSMutableSet *invalidTermsCache;

- (void)saveCache;

- (void)reloadCache;

@property (readonly) NSString *validTermsCacheFilePath;

@property (readonly) NSString *invalidTermsCacheFilePath;

@end
