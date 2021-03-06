//
//  TLFormField.m
//  TLFormView
//
//  Created by Bruno Berisso on 2/24/15.
//  Copyright (c) 2015 Bruno Berisso. All rights reserved.
//

#import "TLFormField.h"
#import "TLFormField+Protected.h"
#import "TLFormAllFields.h"


@implementation UIPopoverController (iPhoneSupport)

+ (BOOL)_popoversDisabled {
    return NO;
}

@end



#pragma mark - HelpTooltipPopoverControler
/**************************************************  HelpTooltipPopoverControler  ***************************************************************/
//This class is the content of the help tooltip. It's only a UITextView that display the value of 'helpText' property

@interface HelpTooltipPopoverControler : UIViewController <UIPopoverPresentationControllerDelegate>
+ (id)helpTooltipControllerWithText:(NSString *)helpText;
@end

@implementation HelpTooltipPopoverControler {
    NSString *text;
    UITextView *textView;
}

+ (id)helpTooltipControllerWithText:(NSString *)helpText {
    HelpTooltipPopoverControler *controller = [[HelpTooltipPopoverControler alloc] init];
    controller->text = helpText;
    controller.modalPresentationStyle = UIModalPresentationPopover;
    controller.popoverPresentationController.delegate = controller;
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.font = [UIFont systemFontOfSize:13];
    textView.scrollEnabled = NO;
    textView.editable = NO;
    textView.selectable = NO;
    textView.text = text;
    [self.view addSubview:textView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[textView]|"
                                                                      options:NSLayoutFormatAlignAllCenterY
                                                                      metrics:0
                                                                        views:NSDictionaryOfVariableBindings(textView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textView]|"
                                                                      options:NSLayoutFormatAlignAllCenterX
                                                                      metrics:0
                                                                        views:NSDictionaryOfVariableBindings(textView)]];
}

- (CGSize)preferredContentSize {
    BOOL is_iPhone = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
    return [textView sizeThatFits:CGSizeMake(is_iPhone ? 200 : 250, INFINITY)];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end


#pragma mark - TLFormField
//The base class for the form fields

@implementation TLFormField {
    UIView *_titleView;
    NSLayoutConstraint *hiddenConstraint;
    UIPopoverController *popover;
}

#pragma mark - Field Setup

+ (instancetype)formFieldWithName:(NSString *)fieldName title:(NSString *)title andDefaultValue:(id)defaultValue {
    return [[self  alloc] initWithName:fieldName title:title andDefaultValue:defaultValue];
}

- (instancetype)initWithName:(NSString *)fieldName title:(NSString *)title andDefaultValue:(id)defaultValue {
    self = [super init];
    
    self.borderStyle = TLFormFieldBorderNone;
    
    if (self) {
        self.fieldName = fieldName;
        self.defautValue = defaultValue;
        self.title = title;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor whiteColor];
        
#ifdef TLFormViewLayoutDebug
        self.backgroundColor = [UIColor colorWithRed:(rand() % 255)/255.0 green:(rand() % 255)/255.0 blue:(rand() % 255)/255.0 alpha:1.0];
#endif
    }
    
    return self;
}

- (void)setupField:(BOOL)editing {
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.borderStyle != TLFormFieldBorderNone) {
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        CGSize size = CGRectIntegral(self.bounds).size;
        
        if (self.borderStyle & TLFormFieldBorderTop) {
            [path moveToPoint:CGPointMake(0, 0.5)];
            [path addLineToPoint:CGPointMake(size.width, 0.5)];
        }
        
        if (self.borderStyle & TLFormFieldBorderRight) {
            [path moveToPoint:CGPointMake(size.width + 0.5, 0.5)];
            [path addLineToPoint:CGPointMake(size.width + 0.5, size.height + 0.5)];
        }
        
        if (self.borderStyle & TLFormFieldBorderBottom) {
            [path moveToPoint:CGPointMake(size.width + 0.5, size.height + 0.5)];
            [path addLineToPoint:CGPointMake(0.5, size.height + 0.5)];
        }
        
        if (self.borderStyle & TLFormFieldBorderLeft) {
            [path moveToPoint:CGPointMake(0.5, size.height)];
            [path addLineToPoint:CGPointMake(0.5, 0.5)];
        }
        
        CAShapeLayer *border = [CAShapeLayer layer];
        border.name = @"TLFomFieldBorderLayer";
        border.path = path.CGPath;
        border.strokeColor = [[UIColor colorWithRed:203/255.0 green:203/255.0 blue:207/255.0 alpha:1.0] CGColor];
        
        for (CALayer *layer in self.layer.sublayers) {
            if ([layer.name isEqualToString:@"TLFomFieldBorderLayer"]) {
                [layer removeFromSuperlayer];
                break;
            }
        }
        
        [self.layer addSublayer:border];
    }
}

- (NSDictionary *)defaultMetrics {
    return @{@"sp": @2.0,    //small padding
             @"np": @8.0,    //normal padding
             @"bp": @12.0};  //big padding
}

#pragma mark - Hidden

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    
    if (hidden) {
        hiddenConstraint = [NSLayoutConstraint constraintWithItem:self
                                                        attribute:NSLayoutAttributeHeight
                                                        relatedBy:0
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1.0
                                                         constant:0.0];
        [self.superview addConstraint:hiddenConstraint];
    } else {
        [self.superview removeConstraint:hiddenConstraint];
        hiddenConstraint = nil;
    }
}

#pragma mark - Value

- (void)setValue:(id)fieldValue {
    
}

- (id)getValue {
    return self.defautValue;
}

#pragma mark - Title View

- (UIView *)titleView {
    
    if (_titleView)
        return _titleView;
    
    UILabel *title = [[UILabel alloc] init];
    title.numberOfLines = 2;
    title.lineBreakMode = NSLineBreakByWordWrapping;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = self.title;
    title.tag = TLFormFieldTitleLabelTag;
    //Set the huggin priprity to make room for the field.
    [title setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    
    if (self.helpText) {
        UIButton *showHelpButton = [[UIButton alloc] init];
        showHelpButton.translatesAutoresizingMaskIntoConstraints = NO;
        showHelpButton.titleLabel.font = [UIFont systemFontOfSize:25];
        [showHelpButton setTitle:@"?" forState:UIControlStateNormal];
        [showHelpButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [showHelpButton addTarget:self action:@selector(showHelpAction:) forControlEvents:UIControlEventTouchUpInside];
        showHelpButton.contentEdgeInsets = UIEdgeInsetsMake(1, 1, 1, 1);
        
        UIView *titleContainer = [[UIView alloc] init];
        titleContainer.translatesAutoresizingMaskIntoConstraints = NO;
        [titleContainer addSubview:title];
        [titleContainer addSubview:showHelpButton];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(title, showHelpButton);
        [titleContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[title]-[showHelpButton]"
                                                                               options:NSLayoutFormatAlignAllCenterY
                                                                               metrics:nil
                                                                                 views:views]];
        [titleContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[showHelpButton]|"
                                                                               options:NSLayoutFormatAlignAllCenterX
                                                                               metrics:nil
                                                                                 views:views]];
        _titleView = titleContainer;
    } else
        _titleView = title;
    
    return _titleView;
}

- (void)showHelpAction:(UIButton *)sender {
    popover = [[UIPopoverController alloc] initWithContentViewController:[HelpTooltipPopoverControler helpTooltipControllerWithText:self.helpText]];
    CGRect finalFrame = [self convertRect:sender.frame fromView:sender.superview];
    [popover presentPopoverFromRect:finalFrame inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
