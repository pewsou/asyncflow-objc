/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASFKExpirationCondition.h"
@class ASFKSecret;
/*
 Secrets are objects used to authorize operations; When API call invoked and secret is provided, it is tested against some other stored secret; if both secrets match, the operation is allowed.
 Secrets are organized by types and roles. There are 3 types: Master, Private and Group. Master secret is single, global and can affect all mailboxes. Private/Group may affect only specific mailbox; Private secret should be created and used by mailbox owners only, while Group secret may be used by owner and group members.
 Each secret may play different roles, while some roles are disabled for different secret types.
 Available Roles:                                              Private     Group       Master
 1. creation of group mailbox                                     x
    by cloning or set operation
 2. Reading                                                       x          x
 3. Popping                                                       x          x
 4. Discarding of mailboxes and groups                            x                      x
 5. unicast                                                       x          x           x
 6. multicast                                                     x          x           x
 7. moderation - blinding/muting of members                       x          x
 8. security - changing secrets for Mailbox, Group, Global        x                      x
 9. issuer - retraction/hiding of posted messages                 x          x
 10. config - update of mailbox operational parameters            x
 11. hosting - addition/removal of members to/from Group mailbox  x          x
 
 Secrets lifetime and configuration:
 All secrets have unlimited lifetime by default, which however can be configured to be temporary: for limited time period, limited number of use attempts or custom lifetime shortening criteria. When lifetime is ended the secret is invalidated forever. Manual invalidation is available too.
 Any secret may be configured to have different properties. Any property may be configured only once.
 */

typedef BOOL(^ASFKSecretComparisonProc)(id secret1,id secret2);
/*!
 @brief Declaration of generic secret entity.
 @discussion secrets are associated with containers and tested each time the container is accessed using high-level API.
 */
@interface ASFKSecret :NSObject{
@private
    id _secretModerator;
    id _secretUnicaster;
    id _secretMulticaster;
    id _secretPopper;
    id _secretReader;
    id _secretDiscarder;
    id _secretCreator;
    id _secretSecurity;
    id _secretConfigurer;
    id _secretHost;
    id _secretIssuer;
}
@property (readonly) ASFKConditionTemporal* timerExpiration;
-(BOOL) matchesUnicasterSecret:(ASFKSecret*)secret;
-(BOOL) matchesMulticasterSecret:(ASFKSecret*)secret;
-(BOOL) matchesReaderSecret:(ASFKSecret*)secret;
-(BOOL) matchesPopperSecret:(ASFKSecret*)secret;
-(BOOL) matchesDiscarderSecret:(ASFKSecret*)secret;
-(BOOL) matchesCreatorSecret:(ASFKSecret*)secret;
-(BOOL) matchesModeratorSecret:(ASFKSecret*)secret;
-(BOOL) matchesHostSecret:(ASFKSecret*)secret;
-(BOOL) matchesIssuerSecret:(ASFKSecret*)secret;
-(BOOL) matchesConfigSecret:(ASFKSecret*)secret;
-(BOOL) matchesSecuritySecret:(ASFKSecret*)secret;

-(BOOL) setMulticasterSecretOnce:(id)secret;
-(BOOL) setUnicasterSecretOnce:(id)secret;
-(BOOL) setReaderSecretOnce:(id)secret;
-(BOOL) setPopperSecretOnce:(id)secret;
-(BOOL) setDiscarderSecretOnce:(id)secret;
-(BOOL) setCreatorSecretOnce:(id)secret;
-(BOOL) setModeratorSecretOnce:(id)secret;
-(BOOL) setIssuerSecretOnce:(id)secret;
-(BOOL) setHostSecretOnce:(id)secret;
-(BOOL) setConfigSecretOnce:(id)secret;
-(BOOL) setSecuritySecretOnce:(id)secret;

-(BOOL) setUnicasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setMulticasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setCreatorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setDiscarderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setModeratorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setIssuerSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setConfigSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setSecuritySecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setReaderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setPopperSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(BOOL) setHostSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;

-(void) invalidateUnicasterSecret;
-(void) invalidateMulticasterSecret;
-(void) invalidateReaderSecret;
-(void) invalidatePopperSecret;
-(void) invalidateDiscarderSecret;
-(void) invalidateCreatorSecret;
-(void) invalidateModeratorSecret;
-(void) invalidateSecuritySecret;
-(void) invalidateIssuerSecret;
-(void) invalidateConfigSecret;
-(void) invalidateHostSecret;
-(void) invalidateAll;
-(BOOL) validSecretModerator;
-(BOOL) validSecretCreator;
-(BOOL) validSecretDiscarder;
-(BOOL) validSecretUnicaster;
-(BOOL) validSecretMulticaster;
-(BOOL) validSecretPopper;
-(BOOL) validSecretReader;
-(BOOL) validSecretHost;
-(BOOL) validSecretSecurity;
-(BOOL) validSecretConfig;
-(BOOL) validSecretIssuer;
-(BOOL) setExpirationDateOnce:(NSDate*)aDate;
-(BOOL) setExpirationDelayOnce:(NSTimeInterval) sec;
-(BOOL) passedExpirationDeadline:(NSDate*)deadline;
-(BOOL) setMaxUsageCountOnce:(NSInteger)maxCount;
-(BOOL) passedMaxUsageCount;
@end
/*!
 @brief Declaration of master secret entity.
 @discussion If applied to container having private secret - the private secret is overriden if master secret is valid and non-nil. Roles available for master key: purging of maibox, deletion of mailbox, messages and users; setting of master secret; unicast, broadcast and multicast. Master secret may not be used for moderation, reading.
 */
@interface ASFKMasterSecret :ASFKSecret

@end
/*!
 @brief Declaration of private secret entity.
 @discussion only container's owner having private secret may use it. Roles available for private secret: purging of mailbox; creation of private mailbox; reading and popping; moderation - muting, blinding and so on; unicast, broadcast and multicast. 
 */
@interface ASFKPrivateSecret :ASFKSecret

@end
/*!
 @brief Declaration of group secret entity.
 @discussion only group owner and group members may use it. Roles available for group secret: purging of mailbox; reading and popping; moderation - muting, blinding and so on.
 */
@interface ASFKGroupSecret :ASFKPrivateSecret

@end

