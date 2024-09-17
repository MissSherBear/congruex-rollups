/*************************************************************************************************
 * SITETRACKER, INC. (“Sitetracker”) CONFIDENTIAL
 * Unpublished Copyright (c) 2013-2024 SITETRACKER, INC., All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of Sitetracker.
 * The intellectual and technical concepts contained herein are proprietary to Sitetracker and
 * may be covered by U.S. and Foreign Patents, patents in process, and are protected by trade
 * secret or copyright law.
 *
 * Dissemination of this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Sitetracker. Access to the source code contained
 * herein is hereby forbidden to anyone except current Sitetracker employees, managers or
 * contractors who have executed Confidentiality and Non-disclosure agreements explicitly
 * covering such access.
 *
 * The copyright notice above does not evidence any actual or intended publication or disclosure
 * of this source code, which includes information that is confidential and/or proprietary, and
 * is a trade secret, of Sitetracker.
 * 
 * @description CongruexWorkLogTrigger
 *
 * @author <A HREF="mailto:rpayne@sitetracker.com">Ronnie Payne</A>
 *
 ***************************************************************************************************/
trigger CongruexWorkLogTrigger on Work_Log__c (before insert, before update, before delete, after insert, after update, after delete) {
    sitetracker.StTriggerFactory.executeTrigger(CongruexWorkLogTriggerHandler.class, true);

}