trigger PermitLiveSyncTrigger on sitetracker__Permit__c (after update) {
    // Set to hold the IDs of permits that need to be synced
    Set<Id> permitIdsToSync = new Set<Id>();

    // Iterate through the updated Permits
    for (sitetracker__Permit__c permit : Trigger.new) {
        sitetracker__Permit__c oldPermit = Trigger.oldMap.get(permit.Id);

        // Check if any of the specified fields have changed
        if (permit.Permit_Owner__c != oldPermit.Permit_Owner__c ||
            permit.Receipt_Date_A__c != oldPermit.Receipt_Date_A__c ||
            permit.Rejected_Date__c != oldPermit.Rejected_Date__c ||
            permit.Submit_Date_A__c != oldPermit.Submit_Date_A__c ||
            permit.Expiration_Date__c != oldPermit.Expiration_Date__c ||
            permit.Effective_Date__c != oldPermit.Effective_Date__c ||
            permit.Permit_Status__c != oldPermit.Permit_Status__c ||
            permit.Permit_Type__c != oldPermit.Permit_Type__c ||
            permit.Primary_Job__c != oldPermit.Primary_Job__c ||
            permit.Name != oldPermit.Name ||
            permit.Id != oldPermit.Id ||
            permit.Total_Permit_Fees__c != oldPermit.Total_Permit_Fees__c ||
            permit.Jurisdiction__c != oldPermit.Jurisdiction__c) {
            
            // Add permit ID to the list to sync
            permitIdsToSync.add(permit.Id);
        }
    }

    // If there are permits to sync, call the ESRI Live Sync method
    if (!permitIdsToSync.isEmpty()) {
         PermitSyncHelper.LiveSyncWithESRI(permitIdsToSync);
    }

    // Method to handle the Live Sync with ESRI
    // public void LiveSyncWithESRI(List<sitetracker__Permit__c> permitIdsToSync) {
    //     for (sitetracker__Permit__c permit : permitIdsToSync) {
    //         // Update the Sync with ESRI checkbox field to sync with ESRI
    //         permit.Sync_with_ESRI__c = true;

    //     }
    // }


}

