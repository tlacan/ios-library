/* Copyright Airship and Contributors */

#import "UAScheduleAction.h"
#import "UAActionAutomation.h"
#import "UAActionScheduleInfo+Internal.h"
#import "UASchedule.h"
#import "UAAirshipAutomationCoreImport.h"

@implementation UAScheduleAction

NSString * const UAScheduleActionDefaultRegistryName = @"schedule_actions";
NSString * const UAScheduleActionDefaultRegistryAlias = @"^sa";
NSString * const kUAScheduleActionDefaultRegistryName = UAScheduleActionDefaultRegistryName; // Deprecated – to be removed in SDK version 14.0. Please use UAScheduleActionDefaultRegistryName.
NSString * const kUAScheduleActionDefaultRegistryAlias = UAScheduleActionDefaultRegistryAlias; // Deprecated – to be removed in SDK version 14.0. Please use UAScheduleActionDefaultRegistryAlias.

- (BOOL)acceptsArguments:(UAActionArguments *)arguments {
    switch (arguments.situation) {
        case UASituationManualInvocation:
        case UASituationWebViewInvocation:
        case UASituationBackgroundPush:
        case UASituationForegroundPush:
        case UASituationAutomation:
            return [arguments.value isKindOfClass:[NSDictionary class]];
        case UASituationLaunchedFromPush:
        case UASituationBackgroundInteractiveButton:
        case UASituationForegroundInteractiveButton:
            return NO;
    }
}

- (void)performWithArguments:(UAActionArguments *)arguments
           completionHandler:(UAActionCompletionHandler)completionHandler {

    NSError *error = nil;

    UAActionScheduleInfo *scheduleInfo = [UAActionScheduleInfo scheduleInfoWithJSON:arguments.value error:&error];
    if (!scheduleInfo) {
        UA_LERR(@"Unable to schedule actions. Invalid schedule payload: %@", scheduleInfo);
        completionHandler([UAActionResult resultWithError:error]);
        return;
    }

    [[UAActionAutomation shared] scheduleActions:scheduleInfo completionHandler:^(UASchedule *schedule) {
        completionHandler([UAActionResult resultWithValue:schedule.identifier]);
    }];
}

@end
