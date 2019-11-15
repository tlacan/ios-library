/* Copyright Airship and Contributors */

#import <Foundation/Foundation.h>
#import "UAModuleLoader.h"
#import "UAExtendedActionsModuleLoaderFactory.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Extended actions module loader.
 */
@interface UAExtendedActionsModuleLoader : NSObject<UAModuleLoader, UAExtendedActionsModuleLoaderFactory>

@end

NS_ASSUME_NONNULL_END
