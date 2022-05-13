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


/*!
 @brief Equals YES if session with given identity exists AND is still processing data batch ; NO otherwise.
 */
-(BOOL) isBusySession:(ASFK_IDENTITY_TYPE)sessionId;

+(long long) runningSessionsCount;
/*!
 @brief Cancels ALL sessions created by ALL instances.
 */
+(void)cancelAllGlobally;
/*!
 @brief Cancels ALL sessions created by this instance.
 */
-(void)cancelAll;
-(void)cancelSession:(ASFK_IDENTITY_TYPE)sessionId;

/*!
 @brief flushes all queued items for all sessions created by this instance.
 */
-(void)flushAll;
/*!
 @brief flushes all queued items for given session ID.
 */
-(void)flushSession:(ASFK_IDENTITY_TYPE)sessionId;

/*!
 @brief flushes all queued items for all sessions.
 */
+(void)flushAllGlobally;

/*!
 @brief sets new class of QoS (i.e. thread priority).
 @param newqos required class of Quality of Service . Allowed values are:QOS_CLASS_USER_INTERACTIVE, QOS_CLASS_UTILITY, QOS_CLASS_BACKGROUND. By default QOS_CLASS_BACKGROUND is set. The parameter will be in effect after restart.
 */
-(void) setQualityOfService:(long)newqos;

/*!
 @brief returns list of session ID's for all sessions created by this instance.
 @return Array of session ID's.
 */
-(NSArray*) getSessions;
/*!
 @brief creates new non-expiring session associated with this instance.
 @param exparams collection of session properties.
 @param sid optional name of session.
 @return Dictionary of return values.
 */
-(NSDictionary* _Nonnull) createSession:(ASFKExecutionParams*_Nullable) exparams sessionId:(id _Nullable ) sid;

@end
#endif /* ASFKPipelinePar */
