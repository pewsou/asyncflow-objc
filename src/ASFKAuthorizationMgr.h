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
#import "ASFKMBSecret.h"
@interface ASFKAuthorizationMgr : NSObject{
    @public ASFKSecretComparisonProc secretProcConfig;
    @public ASFKSecretComparisonProc secretProcCreate;
    @public ASFKSecretComparisonProc secretProcDiscard;
    @public ASFKSecretComparisonProc secretProcRead;
    @public ASFKSecretComparisonProc secretProcPop;
    @public ASFKSecretComparisonProc secretProcSecurity;
    @public ASFKSecretComparisonProc secretProcUnicast;
    @public ASFKSecretComparisonProc secretProcMulticast;
    @public ASFKSecretComparisonProc secretProcHost;
    @public ASFKSecretComparisonProc secretProcIssuer;
    @public ASFKSecretComparisonProc secretProcModerate;

}
@property (readonly) ASFKMasterSecret* masterSecret;
/*!
 @brief sets master secret.
 @discussion some operations require secret to be provided as parameter. Master secret overrides private secret in creation/deletion of group/user, but does not override reading/popping operations. Nil secret means that no secret exists, therefore secret check is skipped.
 @param oldsec old master secret; may be nil.
 @param newsec new master secret; may be nil, in this case master secret will be effectively removed.
 @return YES for successful setting, NO otherwise.
 */
-(BOOL) setMasterSecret:(ASFKMasterSecret*)oldsec newSecret:(ASFKMasterSecret*)newsec;
-(BOOL) isMasterSecretValid:(ASFKMasterSecret*)msecret matcher:(ASFKSecretComparisonProc)match;
-(BOOL) matchCreatorSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchDiscarderSecret:(ASFKSecret*)secCurrent with:(ASFKSecret*)secOther;
-(BOOL) matchReaderSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchPopperSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchUnicasterSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchMulticasterSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchHostSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchSecuritySecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchConfigSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchIssuerSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;
-(BOOL) matchModeratorSecret:(ASFKPrivateSecret*)secCurrent with:(ASFKPrivateSecret*)secOther;


@end
