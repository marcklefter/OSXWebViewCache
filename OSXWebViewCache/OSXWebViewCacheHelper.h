
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "GCNetworkReachability.h"

@class CachedURL;

@interface OSXWebViewCacheHelper : NSObject

@property (nonatomic, readonly) GCNetworkReachability *reachability;

/** Core Data related properties and methods. */

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

- (CachedURL *)fetchOne:(NSPredicate *)onePredicate;

// ...

+ (instancetype)sharedInstance;

@end
