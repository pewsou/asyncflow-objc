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
//
//  Created by Boris Vigman on 05/04/2019.
//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
#include <mach/mach.h>
#include <mach/mach_time.h>
@interface ASFKBase (Internal)
+(uint64_t) getTimestamp;
+(ASFK_IDENTITY_TYPE) concatIdentity:(ASFK_IDENTITY_TYPE)primaryId withIdentity:(ASFK_IDENTITY_TYPE)secondaryId;
+(ASFK_IDENTITY_TYPE) generateIdentity;
+(NSString*) generateRandomString;
+(NSNumber*) generateRandomNumber;

-(BOOL) isCancellationRequested;
-(void) registerSession:(ASFKControlBlock*)cblk;
-(ASFKControlBlock*) newSession;
-(ASFKControlBlock*) newSession:(ASFK_IDENTITY_TYPE)sessionId andSubsession:(ASFK_IDENTITY_TYPE)subId;
-(void)forgetSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void)forgetAllSessions;
-(void)terminate:(ASFKControlBlock*)cblk;
@end
