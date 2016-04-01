
#import "CachedURL.h"
#import "OSXWebViewCacheHelper.h"

#import "CachedURLProtocol.h"

@interface CachedURLProtocol () <NSURLConnectionDelegate>

@property (nonatomic) NSURLConnection *connection;
@property (nonatomic) NSMutableData *mutableData;
@property (nonatomic) NSURLResponse *response;

@end

@implementation CachedURLProtocol

static NSMutableArray *allowedDomains;

+ (void)setDomains:(NSArray *)domains
{
    allowedDomains = [NSMutableArray array];
    for (NSString *domain in domains)
    {
        [allowedDomains addObject:[NSURL URLWithString:domain]];
    }
}

#pragma mark NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    BOOL passed = NO;
    
    for (NSURL *domain in allowedDomains)
    {
        // ensure that requested URL's host matches the allowed domain. E.g., if the host is 'www.example.com', the
        // allowed domain must be either 'example.com' (matches all subdomains) or 'www.example.com' for the URL to
        // match.
        if ([request.URL.host rangeOfString:domain.host].location != NSNotFound &&
            [request.URL.scheme isEqualToString:domain.scheme] &&
            request.URL.port == domain.port)
        {
            passed = YES;
        }
    }
    
    if (!passed) return NO;
    
    // ...
    
    if ([NSURLProtocol propertyForKey:@"WebViewCachingURLProtocolHandledKey" inRequest:request])
    {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    OSXWebViewCacheHelper *helper = [OSXWebViewCacheHelper sharedInstance];
    
    // ...
    
    if ([helper.reachability isReachable])
    {
        
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        [NSURLProtocol setProperty:@(YES) forKey:@"WebViewCachingURLProtocolHandledKey" inRequest:newRequest];
        
        self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
    }
    else
    {
        NSLog(@"[OSXWebViewCache] Offline - fetching URL from cache: %@", self.request.URL.absoluteString);
        
        CachedURL *cachedUrl = (CachedURL *) [helper fetchOne:[NSPredicate predicateWithFormat:@"url == %@",
                                                               self.request.URL.absoluteString]];
        
        // if the network is offline and the resource has not been previously cached, abort loading.
        if (!cachedUrl)
        {
            NSLog(@"[OSXWebViewCache] Offline - cannot fetch URL from cache: %@", self.request.URL.absoluteString);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kCachedURLResourceNotAvailableOffline
                                                                    object:nil
                                                                  userInfo:@{ @"url":
                                                                                  self.request.URL.absoluteString
                                                                              }];
            });
            
            return [self stopLoading];
        }
        
        [self fetchCachedURL:cachedUrl];
    }
}

- (void)stopLoading
{
    [self.connection cancel];
    self.connection = nil;
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSPredicate *onePredicate = [NSPredicate predicateWithFormat:@"url == %@", self.request.URL.absoluteString];
    
    CachedURL *cachedUrl = (CachedURL *) [[OSXWebViewCacheHelper sharedInstance] fetchOne:onePredicate];
    if (cachedUrl)
    {
        // retrieve the value of the "Last-Modified" header.
        NSString *lastModifiedString = ((NSHTTPURLResponse *) response).allHeaderFields[@"Last-Modified"];
        
        // determine whether or not the response contains a more recent version of the requested resource.
        NSComparisonResult result = [self compareTimestamp:lastModifiedString cachedTimestamp:cachedUrl.timestamp];
        if (result != NSOrderedDescending)
        {
            // the cached version is up to date, load the cached resource.
            NSLog(@"[OSXWebViewCache] Fetching URL from cache: %@", self.request.URL.absoluteString);
            
            [self fetchCachedURL:cachedUrl];
            
            return [self stopLoading];
        }
    }
    
    // the cached version of the requested resource needs to be updated, continue loading.
    
    self.response = response;
    self.mutableData = [[NSMutableData alloc] init];
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
    
    // ...
    
    [self.mutableData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    
    // ...
    
    CachedURL*(^makeCachedURL)(NSManagedObjectContext *) = ^CachedURL*(NSManagedObjectContext *moc) {
        CachedURL *entity = [NSEntityDescription insertNewObjectForEntityForName:@"CachedURL"
                                                          inManagedObjectContext:moc];
        
        entity.data      = self.mutableData;
        entity.url       = self.request.URL.absoluteString;
        entity.timestamp = [NSDate date];
        entity.mimeType  = self.response.MIMEType;
        entity.encoding  = self.response.textEncodingName;
        
        return entity;
    };
    
    // ...
    
    OSXWebViewCacheHelper *helper = [OSXWebViewCacheHelper sharedInstance];
    
    [helper.managedObjectContext performBlockAndWait:^{
        
        CachedURL *cachedUrl = (CachedURL *) [helper fetchOne:[NSPredicate predicateWithFormat:@"url == %@",
                                                               self.request.URL.absoluteString]];
        
        if (cachedUrl)
        {
            // remove the cached resource for the current request and cache anew.
            [cachedUrl.managedObjectContext deleteObject:cachedUrl];
        }
        
        cachedUrl = makeCachedURL(helper.managedObjectContext);
        
        NSError *error = nil;
        if ([helper.managedObjectContext save:&error])
        {
            NSLog(@"[OSXWebViewCache] Caching URL: %@", cachedUrl.url);
        }
    }];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
}

// ...

- (void)fetchCachedURL:(CachedURL *)cachedUrl
{
    NSData      *data       = cachedUrl.data;
    NSString    *mimeType   = cachedUrl.mimeType;
    NSString    *encoding   = cachedUrl.encoding;
    
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL
                                                        MIMEType:mimeType
                                           expectedContentLength:data.length
                                                textEncodingName:encoding];
    
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:data];
    [self.client URLProtocolDidFinishLoading:self];
}

- (NSComparisonResult)compareTimestamp:(NSString *)lastModified cachedTimestamp:(NSDate *)timestamp
{
    NSDateFormatter *lastModifiedFormatter = [[NSDateFormatter alloc] init];
    [lastModifiedFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [lastModifiedFormatter setDateFormat:@"EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"];
    
    NSDate *lastModifiedDate = [lastModifiedFormatter dateFromString:lastModified];
    
    return [lastModifiedDate compare:timestamp];
}

@end
