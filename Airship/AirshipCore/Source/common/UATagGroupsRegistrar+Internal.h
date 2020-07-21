/* Copyright Airship and Contributors */

#import <Foundation/Foundation.h>

#import "UARuntimeConfig.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAPendingTagGroupStore+Internal.h"
#import "UATagGroupsAPIClient+Internal.h"
#import "UAComponent+Internal.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const UAAirshipTagGroupSentNotification;

@interface UATagGroupsRegistrar : UAComponent

///---------------------------------------------------------------------------------------
/// @name Tag Groups Registrar Methods
///---------------------------------------------------------------------------------------

/**
 * The pending tag group store.
 */
@property (nonatomic, strong) UAPendingTagGroupStore *pendingTagGroupStore;

/**
 * Factory method to create a tag groups registrar.
 * @param config The Airship config.
 * @param dataStore The shared data store.
 * @param pendingTagGroupStore The pending tag group store.
 * @return A new tag groups registrar instance.
 */
+ (instancetype)tagGroupsRegistrarWithConfig:(UARuntimeConfig *)config
                                   dataStore:(UAPreferenceDataStore *)dataStore
                             pendingTagGroupStore:(UAPendingTagGroupStore *)pendingTagGroupStore;

/**
 * Factory method to create a tag groups registrar. Used for testing.
 * @param dataStore The shared data store.
 * @param pendingTagGroupStore The pending tag group store.
 * @param apiClient The internal tag groups API client.
 * @param operationQueue An NSOperation queue used to synchronize changes to tag groups.
 * @param application The application.
 * @return A new tag groups registrar instance.
 */
+ (instancetype)tagGroupsRegistrarWithDataStore:(UAPreferenceDataStore *)dataStore
                                pendingTagGroupStore:(UAPendingTagGroupStore *)pendingTagGroupStore
                                      apiClient:(UATagGroupsAPIClient *)apiClient
                                 operationQueue:(NSOperationQueue *)operationQueue
                                    application:(UIApplication *)application;

/**
 * Update the tag groups for the given identifier.
 * @param channelID The channel identifier.
 */
- (void)updateTagGroupsForID:(NSString *)channelID;

/**
 * Add tags to a tag group. To update the server, make all of your changes,
 * then call `updateTagGroupsForID:type:`.
 *
 * @param tags Array of tags to add.
 * @param tagGroupID Tag group ID string.
 */
- (void)addTags:(NSArray *)tags group:(NSString *)tagGroupID;

/**
 * Remove tags from a tag group. To update the server, make all of your changes,
 * then call `updateTagGroupsForID:type:`.
 *
 * @param tags Array of tags to remove.
 * @param tagGroupID Tag group ID string.
 */
- (void)removeTags:(NSArray *)tags group:(NSString *)tagGroupID;

/**
 * Set tags for a tag group. To update the server, make all of your changes,
 * then call `updateTagGroupsForID:type:`.
 *
 * @param tags Array of tags to set.
 * @param tagGroupID Tag group ID string.
 */
- (void)setTags:(NSArray *)tags group:(NSString *)tagGroupID;

/**
 * Clears all pending tag updates.
 *
 */
- (void)clearAllPendingTagUpdates;

@end

NS_ASSUME_NONNULL_END
