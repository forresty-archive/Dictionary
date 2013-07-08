//
//  DictionaryTableHeaderView.h
//  Dictionary
//
//  Created by Forrest Ye on 7/2/13.
//
//

#import <UIKit/UIKit.h>

@interface FFSolidColorTableHeaderView : UIView


+ (instancetype)viewWithText:(NSString *)text;

@property (nonatomic) UILabel *textLabel;


@end
