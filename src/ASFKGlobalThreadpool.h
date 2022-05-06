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

#import <Foundation/Foundation.h>
#import "ASFKBase.h"
#import "ASFKPipelineSession.h"
@interface ASFKGlobalThreadpool : NSObject
+(ASFKGlobalThreadpool *)sharedManager ;

-(long long) runningSessionsCount;
-(long long) pausedSessionsCount;
-(void) postDataAsArray:(NSArray*)data forSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) postDataAsOrderedSet:(NSOrderedSet*)set forSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) postDataAsUnorderedSet:(NSSet*)data forSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) postDataAsDictionary:(NSDictionary*)data forSession:(ASFK_IDENTITY_TYPE)sessionId;
-(BOOL) addSession:(ASFKPipelineSession*)aseq withId:(ASFK_IDENTITY_TYPE)identity;

-(ASFKPipelineSession*) getThreadpoolSessionWithId:(ASFK_IDENTITY_TYPE)identity;
-(NSArray*) getThreadpoolSessionsList;
-(void) cancelSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) cancelAll;
-(BOOL) isBusySession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) flushSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) flushAll;
-(long) itemsCountForSession:(ASFK_IDENTITY_TYPE)sessionId;
@end
