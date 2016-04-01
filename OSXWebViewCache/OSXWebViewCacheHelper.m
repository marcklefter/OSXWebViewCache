
#import "OSXWebViewCacheHelper.h"

@interface OSXWebViewCacheHelper ()

@property (nonatomic, readwrite) GCNetworkReachability *reachability;

/** Core Data related properties. */
@property (nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;

@property (nonatomic) NSManagedObjectModel *managedObjectModel;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSURL *persistentStoreUrl;

@end

@implementation OSXWebViewCacheHelper

+ (instancetype)sharedInstance;
{
    static id shared;
    static dispatch_once_t once;
    
    dispatch_once(&once, ^{ shared = [[self alloc] init]; });
    
    return shared;
}

// ...

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _reachability = [GCNetworkReachability reachabilityForInternetConnection];
    }
    
    return self;
}

// ...

// Core Data related methods.

/** Fetch exactly one CachedURL entity. */
- (CachedURL *)fetchOne:(NSPredicate *)onePredicate
{
    NSFetchRequest      *fetchRequest   = [NSFetchRequest new];
    NSEntityDescription *entity         = [NSEntityDescription entityForName:@"CachedURL"
                                                      inManagedObjectContext:self.managedObjectContext];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:onePredicate];
    
    __block NSError *error;
    __block NSArray *result;
    
    [self.managedObjectContext performBlockAndWait:^{
        result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    
    if (result && result.count == 1)
    {
        return (CachedURL *) result[0];
    }
    
    return nil;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"CachedURLModel"
                                                               withExtension:@"momd"];
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    // ...
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                   initWithManagedObjectModel:self.managedObjectModel];
    
    NSError         *error      = nil;
    NSURL           *storeURL   = [self.persistentStoreUrl URLByAppendingPathComponent:@"CachedURLModel.sqlite"];
    NSDictionary    *options    = @{
                                    NSMigratePersistentStoresAutomaticallyOption:
                                        @YES,
                                    
                                    NSInferMappingModelAutomaticallyOption:
                                        @YES
                                    };
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a 
         shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a 
         file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning 
         and Data Migration Programming Guide" for details.
         
         */
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)persistentStoreUrl
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    libraryURL = [libraryURL URLByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier];
    
    BOOL isDir;
    if (![fileManager fileExistsAtPath:libraryURL.path isDirectory:&isDir] || !isDir)
    {
        [fileManager createDirectoryAtPath:libraryURL.path
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:nil];
    }
    
    return libraryURL;
}

@end
