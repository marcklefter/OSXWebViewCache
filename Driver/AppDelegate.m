
#import <WebKit/WebKit.h>

#import <OSXWebViewCache/CachedURLProtocol.h>

#import "AppDelegate.h"

#define kWebViewUrl @"http://localhost:8081/src/index.html"

@interface AppDelegate () <WebUIDelegate>

@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, strong) WebView *webview;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"WebKitDeveloperExtras"])
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // ...
    
    [self.window center];
    
    // ...
    
    // enable URL caching for selected domains.
    [CachedURLProtocol setDomains:@[@"http://localhost:8081"]];
    [NSURLProtocol registerClass:[CachedURLProtocol class]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNotification:)
                                                 name:nil
                                               object:nil];
    
    // ...
    
    self.webview = [[WebView alloc] initWithFrame:[self.window.contentView frame]];
    [self.window.contentView addSubview:self.webview];
    
    [self.webview.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kWebViewUrl]]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

// ...

- (void)didReceiveNotification:(NSNotification *)notification
{
    if ([notification.name isEqualToString:kCachedURLResourceNotAvailableOffline])
    {
        NSLog(@"Could not fetch resource %@ while offline", notification.userInfo[@"url"]);
    }
}

@end