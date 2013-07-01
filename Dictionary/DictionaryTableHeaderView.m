//
//  DictionaryTableHeaderView.m
//  Dictionary
//
//  Created by Forrest Ye on 7/2/13.
//
//

#import "DictionaryTableHeaderView.h"

#import "DictionaryViewDefinitions.h"

@interface DictionaryTableHeaderView ()

@property UILabel *label;

@end

@implementation DictionaryTableHeaderView


+ (instancetype)viewWithText:(NSString *)text {
  DictionaryTableHeaderView *view = [self sharedInstance];

  view.label.text = text;

  return view;
}


# pragma mark - private


+ (instancetype)sharedInstance {
  static DictionaryTableHeaderView *_instance = nil;

  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });

  return _instance;
}

- (instancetype)init {
  self = [super initWithFrame:CGRectMake(0, 0, 320, 30)];

  if (self) {
    self.backgroundColor = DICTIONARY_BASIC_TEXT_COLOR;
    self.alpha = 0.9;

    _label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 310, 30)];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.textColor = [UIColor whiteColor];
    self.label.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];

    [self addSubview:self.label];
  }

  return self;
}

@end
