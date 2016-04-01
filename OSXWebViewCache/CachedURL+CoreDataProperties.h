
#import "CachedURL.h"

NS_ASSUME_NONNULL_BEGIN

@interface CachedURL (CoreDataProperties)

@property (nullable, nonatomic, retain) NSData *data;
@property (nullable, nonatomic, retain) NSString *encoding;
@property (nullable, nonatomic, retain) NSString *mimeType;
@property (nullable, nonatomic, retain) NSDate *timestamp;
@property (nullable, nonatomic, retain) NSString *url;

@end

NS_ASSUME_NONNULL_END
