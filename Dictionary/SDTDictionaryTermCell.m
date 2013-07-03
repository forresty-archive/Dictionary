//
//  DictionaryTermCell.m
//  Dictionary
//
//  Created by Forrest Ye on 7/1/13.
//
//

#import "SDTDictionaryTermCell.h"
#import "SDTDictionaryViewDefinitions.h"

@implementation SDTDictionaryTermCell

- (instancetype)init {
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDictionaryTermCellID];

  if (self) {
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    backgroundView.backgroundColor = DICTIONARY_BASIC_TINT_COLOR;
    self.selectedBackgroundView = backgroundView;
  }

  return self;
}


- (void)changeToType:(DictionaryTableViewCellType)type {
  [self changeToType:type withText:self.textLabel.text];
}


- (void)changeToType:(DictionaryTableViewCellType)type withText:(NSString *)text {
  self.tag = type;
  self.textLabel.highlightedTextColor = DICTIONARY_BASIC_TEXT_COLOR;
  self.textLabel.text = text;

  switch (type) {
    case DictionaryTableViewCellTypeNormal: {
      self.selectionStyle = UITableViewCellSelectionStyleBlue;
      self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      self.textLabel.textAlignment = NSTextAlignmentLeft;
      self.textLabel.font = DICTIONARY_BASIC_TEXT_FONT;
      self.textLabel.textColor = DICTIONARY_BASIC_TEXT_COLOR;
      break;
    }
    case DictionaryTableViewCellTypeAction: {
      self.selectionStyle = UITableViewCellSelectionStyleBlue;
      self.accessoryType = UITableViewCellAccessoryNone;
      self.textLabel.textAlignment = NSTextAlignmentCenter;
      self.textLabel.font = DICTIONARY_BASIC_ACTION_FONT;
      self.textLabel.textColor = DICTIONARY_BASIC_TEXT_COLOR;
      break;
    }
    case DictionaryTableViewCellTypeDisabled: {
      self.selectionStyle = UITableViewCellSelectionStyleNone;
      self.accessoryType = UITableViewCellAccessoryNone;
      self.textLabel.textAlignment = NSTextAlignmentLeft;
      self.textLabel.font = DICTIONARY_BASIC_TEXT_FONT;
      self.textLabel.textColor = [UIColor grayColor];
      break;
    }
  }
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
  [super setHighlighted:highlighted animated:animated];

  if (self.tag == DictionaryTableViewCellTypeNormal) {
    if (highlighted) {
      self.accessoryType = UITableViewCellAccessoryNone;
    } else {
      self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
}


@end
