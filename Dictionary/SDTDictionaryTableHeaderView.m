//
//  DictionaryTableHeaderView.m
//  Dictionary
//
//  Created by Forrest Ye on 7/2/13.
//
//

#import "SDTDictionaryTableHeaderView.h"


@implementation SDTDictionaryTableHeaderView


+ (instancetype)viewWithText:(NSString *)text {
  SDTDictionaryTableHeaderView *view = [self sharedInstanceWithText:text];

  return view;
}


# pragma mark - private


+ (instancetype)sharedInstanceWithText:(NSString *)text {
  static NSMutableDictionary* _instances = nil;

  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _instances = [@{} mutableCopy];
  });

  if (!_instances[text]) {
    SDTDictionaryTableHeaderView *view = [[self alloc] initWithText:text];
    _instances[text] = view;
  }

  NSAssert(_instances.count == 1 || _instances.count == 2, @"should have 1 or 2 items");

  return _instances[text];
}


- (instancetype)initWithText:(NSString *)text {
  self = [super initWithFrame:CGRectMake(0, 0, 320, 30)];

  if (self) {
    self.backgroundColor = [UIColor colorWithRed:130.0/255 green:85.0/255 blue:48.0/255 alpha:1];
    self.alpha = 0.9;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 310, 30)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    label.text = text;

    [self addSubview:label];
  }

  return self;
}


@end
