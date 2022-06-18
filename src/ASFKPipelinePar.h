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

#ifndef ASFKPipelinePar_h
#define ASFKPipelinePar_h
/*!
 @see ASFKLinearFlow
 @brief This class provides pipelined execution's functionality. For N Routines it takes Routine P0 and applies it to item D0. Upon completion P0 is applied to D1 while P1 is concurrently applied to D0 and so on.
 */
@interface ASFKPipelinePar : ASFKLinearFlow

-(BOOL) isPausedSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;
-(long long) itemsCountForSession:(_Null_unspecified id)sessionId;

/*!
 @brief Equals YES if session with given identity exists AND is still processing data batch ; NO otherwise.
 */
-(BOOL) isBusySession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;

-(long long) getRunningSessionsCount;
-(long long) getPausedSessionsCount;

/*!
 @brief Cancels ALL sessions created by this instance.
 */
-(void)cancelAll;
/*!
 @brief Cancels session with given id.
 */
-(void)cancelSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;
/*!
 @brief flushes all queued items for all sessions created by this instance.
 */
-(void)flushAll;
/*!
 @brief flushes all queued items for given session ID.
 */
-(void)flushSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;

/*!
 @brief flushes all queued items for all sessions created by this instance.
 */
-(void)pauseAll;
/*!
 @brief flushes all queued items for given session ID.
 */
-(void)pauseSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;

/*!
 @brief flushes all queued items for all sessions created by this instance.
 */
-(void)resumeAll;
/*!
 @brief flushes all queued items for given session ID.
 */
-(void)resumeSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;

/*!
 @brief sets new class of QoS (i.e. thread priority).
 @param newqos required class of Quality of Service . Allowed values are:QOS_CLASS_USER_INTERACTIVE, QOS_CLASS_UTILITY, QOS_CLASS_BACKGROUND. By default QOS_CLASS_BACKGROUND is set. The parameter will be in effect after restart.
 */
-(void) setQualityOfService:(long)newqos;

/*!
 @brief returns list of session ID's for all sessions created by this instance.
 @return Array of session ID's.
 */
-(NSArray* _Null_unspecified) getSessions;
/*!
 @brief creates new non-expiring session associated with this instance.
 @param exparams collection of session properties. May be nil; in that case default parameters will be adopted.
 @param sid optional name of session. If nil, then random value will be assigned.
 @return Dictionary of return values.
 */
-(NSDictionary* _Nonnull) createSession:(ASFKExecutionParams*_Nullable) exparams sessionId:(id _Nullable ) sid;

@end
#endif /* ASFKPipelinePar */
