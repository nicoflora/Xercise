//
//  IGLDropDownItem.m
//  IGLDropDownMenuDemo
//
//  Created by Galvin Li on 8/30/14.
//  Copyright (c) 2014 Galvin Li. All rights reserved.
//
/*
 The MIT License (MIT)
 
 Copyright (c) 2014 Galvin Li
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import "IGLDropDownItem.h"
#import <UIKit/UIKit.h>
#import "Xercise-Swift.h"

@interface IGLDropDownItem ()

@property (nonatomic, strong) UIView *customView;

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation IGLDropDownItem

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCustomView:(UIView *)customView
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self addSubview:customView];
        customView.userInteractionEnabled = NO;
        self.customView = customView;
    }
    return self;
}

- (void)commonInit
{
    _paddingLeft = 0; //5
    _showBackgroundShadow = NO;
    _backgroundColor = [UIColor whiteColor];
    [self initView];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if (self.customView) {
        [self.customView setFrame:self.bounds];
    } else {
        [self.bgView setFrame:self.bounds];
        [self updateLayout];
    }
    
}

- (void)initView
{
    self.bgView = [[UIView alloc] init];
    self.bgView.userInteractionEnabled = NO;
    self.bgView.layer.shouldRasterize = YES;
    [self.bgView setFrame:self.bounds];
    [self addSubview:self.bgView];
    self.bgView.backgroundColor = self.backgroundColor;
    self.showBackgroundShadow = _showBackgroundShadow;

    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.contentMode = UIViewContentModeCenter;
    [self addSubview:self.iconImageView];
    
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.numberOfLines = 1;
    self.textLabel.textColor = [[UIColor alloc]initWithHexString:@"#2c4b85"];
    self.textLabel.font = [UIFont fontWithName:@"Marker Felt" size:20];
    self.textLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.textLabel];
    
    // Testing corner radius
    self.bgView.layer.cornerRadius = 10;
    
    [self updateLayout];
    
}

- (void)setIconImage:(UIImage *)iconImage
{
    _iconImage = iconImage;
    [self.iconImageView setImage:self.iconImage];
    
    [self updateLayout];
}

- (void)setShowBackgroundShadow:(BOOL)showBackgroundShadow
{
    _showBackgroundShadow = showBackgroundShadow;
    if (self.showBackgroundShadow) {
        self.bgView.layer.shadowColor = [UIColor grayColor].CGColor;
        self.bgView.layer.shadowOffset = CGSizeMake(0, 0);
        self.bgView.layer.shadowOpacity = 0.5;
    } else {
        self.bgView.layer.shadowOpacity = 0.0;
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    self.bgView.backgroundColor = self.backgroundColor;
}

- (void)updateLayout
{
    
    CGFloat selfWidth = CGRectGetWidth(self.bounds);
    CGFloat selfHeight = CGRectGetHeight(self.bounds);
    
    [self.iconImageView setFrame:CGRectMake(self.paddingLeft, 0, selfHeight, selfHeight)];
    if (self.iconImage) {
        [self.textLabel setFrame:CGRectMake(CGRectGetMaxX(self.iconImageView.frame), 0, selfWidth - CGRectGetMaxX(self.iconImageView.frame), selfHeight)];
    } else {
        [self.textLabel setFrame:CGRectMake(self.paddingLeft, 0, selfWidth, selfHeight)];
    }
}

- (void)setPaddingLeft:(CGFloat)paddingLeft
{
    _paddingLeft = paddingLeft;
    
    [self updateLayout];
}

- (void)setObject:(id)object
{
    _object = object;
}

- (void)setText:(NSString *)text
{
    _text = text;
    self.textLabel.text = self.text;
}

- (id)copyWithZone:(NSZone *)zone
{
    IGLDropDownItem *itemCopy;
    if (_customView) {
        itemCopy = [[IGLDropDownItem alloc] initWithCustomView:_customView];
    } else {
        itemCopy = [[IGLDropDownItem alloc] init];
        itemCopy.iconImage = _iconImage;
        itemCopy.text = _text;
        itemCopy.paddingLeft = _paddingLeft;
        itemCopy.showBackgroundShadow = _showBackgroundShadow;
        itemCopy.backgroundColor = _backgroundColor;
    }
    
    itemCopy.index = _index;
    itemCopy.object = _object;

    
    return itemCopy;
}

@end
