//
//  DictionaryTermCell.m
//  Dictionary
//
//  Created by Forrest Ye on 7/1/13.
//
//

#import "DictionaryTermCell.h"
#import "DictionaryViewDefinitions.h"

@implementation DictionaryTermCell

- (instancetype)init {
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDictionaryTermCellID];

  if (self) {
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.backgroundColor = DICTIONARY_BASIC_TINT_COLOR;
    self.selectedBackgroundView = backgroundView;
  }

  return self;
}

@end
