
#import <Foundation/Foundation.h>

#define kCachedURLResourceNotAvailableOffline @"CachedURLResourceNotAvailableOffline"

/**
 * 'CachedURLProtocol' enables caching of URL resources loaded by an OSX webview.
 *
 * When a request is made for a URL, the URL's host name is checked against a list of user-supplied domain names to
 * ensure that its corresponding resource may be cached.
 *
 * The request is executed if it passes the domain name check; if the requested URL resource has previously been cached,
 * the corresponding timestamp is compared to the 'Last-Modified' response header. If the cached URL is up to date, 
 * its data is returned immediately, otherwise the resource is fetched and the cache is updated with the most recent 
 * version.
 *
 * 'CachedURLProtocol' will also serve cached URL resources if the network is offline. While offline, if a resource is 
 * requested which has not been previously cached, a 'kCachedURLResourceNotAvailableOffline' notification is sent.
 *
 * Add URL caching to a webview instance as follows:
 *
 * // set the list of domain names for which URL caching should be enabled.
 * [CachedURLProtocol setDomains:@[@"http://example.com"]];
 *
 * [NSURLProtocol registerClass:[CachedURLProtocol class]];
 */
@interface CachedURLProtocol : NSURLProtocol

/** 
 * @param domains an array of domain names. Each domain name must include the URL scheme (such as 'http://' or 
 *                  'https://'). To enable caching for the domain 'example.com' (and all its subdomains),
 *                  pass the following array: @[@"http://example.com"].
 */
+ (void)setDomains:(NSArray *)domains;

@end
