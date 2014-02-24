#import "TMViewController.h"

#import "TMInstanceMethodSwizzler.h"
#import "TMTimeoutManager.h"

static NSTimeInterval const timeout = 3.;

@interface TMViewController ()

@property (weak, nonatomic) IBOutlet UIButton *startTest;

@property (weak, nonatomic) IBOutlet UILabel *testHint;
@property (weak, nonatomic) IBOutlet UIButton *stopTest;

@property (weak, nonatomic) IBOutlet UILabel *buttonPressedIndicator;
@property (weak, nonatomic) IBOutlet UILabel *timeoutIndicator;

@property (strong, nonatomic) TMTimeoutManager *timeoutManager;

@end

@implementation TMViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        TMInstanceMethodSwizzler *instanceMethodSwizzler = [[TMInstanceMethodSwizzler alloc] init];
        _timeoutManager = [[TMTimeoutManager alloc] initWithInstanceMethodSwizzler:instanceMethodSwizzler];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self resetTest];
}

- (void)resetTest
{
    [self startTestEnabled:YES stopTestEnabled:NO testHintHidden:YES];

    self.buttonPressedIndicator.backgroundColor = [UIColor lightGrayColor];
    self.timeoutIndicator.backgroundColor = [UIColor lightGrayColor];
}

- (IBAction)startTest:(id)sender
{
    [self resetTest];
    [self startTestEnabled:NO stopTestEnabled:YES testHintHidden:NO];

    [self.timeoutManager expectSelectorToBeCalled:@selector(stopTest:)
                                       withObject:self
                                    beforeTimeout:timeout
                                      calledBlock:^{
                                          self.buttonPressedIndicator.backgroundColor = [UIColor greenColor];
                                      } timeoutBlock:^{
                                          self.timeoutIndicator.backgroundColor = [UIColor redColor];
                                          [self startTestEnabled:YES stopTestEnabled:NO testHintHidden:YES];
                                      }];
}

- (IBAction)stopTest:(id)sender
{
    [self startTestEnabled:YES stopTestEnabled:NO testHintHidden:YES];
}

- (void)startTestEnabled:(BOOL)startTestEnabled stopTestEnabled:(BOOL)stopTestEnabled testHintHidden:(BOOL)testHintHidden
{
    self.startTest.enabled = startTestEnabled;
    self.stopTest.enabled = stopTestEnabled;
    self.testHint.hidden = testHintHidden;
}

@end
