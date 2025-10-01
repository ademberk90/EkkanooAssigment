public class ContactActivityIndicatorBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    List<String> errorLogs = new List<String>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // select query for contact with required fields
        return Database.getQueryLocator([
            SELECT Id, Activity_Indicator__c, Account.Active__c
            FROM Contact
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> contactList) {
        try{
            Set<Id> contactIds = new Set<Id>();
            Map<Id, String> accountStatusMap = new Map<Id, String>();
            
            for(Contact c : contactList){
                contactIds.add(c.Id);
                accountStatusMap.put(c.Id, c.Account != null ? c.Account.Active__c : null);
            }
            
            // Query for Task/Event last modified dates
            Map<Id, Date> lastActivityDateMap = new Map<Id, Date>();
            
            List<AggregateResult> taskAgg = [
                SELECT WhoId contactId, MAX(LastModifiedDate) lastDate
                FROM Task
                WHERE WhoId IN :contactIds
                GROUP BY WhoId
            ];
            for(AggregateResult ar : taskAgg){
                lastActivityDateMap.put((Id)ar.get('contactId'), ((Datetime)ar.get('lastDate')).date());
            }
            
            List<AggregateResult> eventAgg = [
                SELECT WhoId contactId, MAX(LastModifiedDate) lastDate
                FROM Event
                WHERE WhoId IN :contactIds
                GROUP BY WhoId
            ];
            for(AggregateResult ar : eventAgg){
                Date current = lastActivityDateMap.get((Id)ar.get('contactId'));
                Date newDate = ((Datetime)ar.get('lastDate')).date();
                if(current == null || newDate > current){
                    lastActivityDateMap.put((Id)ar.get('contactId'), newDate);
                }
            }
            
            // Contact update list
            List<Contact> updateList = new List<Contact>();
            
            for(Contact c : contactList){
                Integer indicator;
                if(accountStatusMap.get(c.Id) == 'No'){
                    indicator = 0;
                } else {
                    Date lastDate = lastActivityDateMap.get(c.Id);
                    if(lastDate == null){
                        indicator = -1;
                    } else {
                        Integer daysAgo = Date.today().daysBetween(lastDate);
                        if(daysAgo <= 90){
                            indicator = 1;
                        } else if(daysAgo <= 180){
                            indicator = 2;
                        } else if(daysAgo <= 270){
                            indicator = 3;
                        } else if(daysAgo <= 360){
                            indicator = 4;
                        } else {
                            indicator = 5;
                        }
                    }
                }
                // check activity indicator fields is changed or not. 
                // So won't add redundant record. ( For performance issues )
                if (c.Activity_Indicator__c != indicator) {
                    c.Activity_Indicator__c = indicator;
                    updateList.add(c);
                }
            }
            
            if(!updateList.isEmpty()){
                Database.SaveResult[] results = Database.update(updateList, false);
                
                for(Integer i = 0; i < results.size(); i++){
                    if(!results[i].isSuccess()){
                        errorLogs.add('Contact ' + updateList[i].Id + ': ' + results[i].getErrors()[0].getMessage());
                        
                    }
                }
            }
            
        } catch(Exception e){
            // Unexpected exception
            System.debug('Message: ' + e.getMessage());
            System.debug('StackTrace: ' + e.getStackTraceString());
            
            errorLogs.add('Critical exception in chunk: ' + e.getMessage() + '\n' + e.getStackTraceString());

            
        }
    }
    
    public void finish(Database.BatchableContext bc){
       for(String log : errorLogs){	
           	// Alternatively we can log, send mail. 
            System.debug(log);
        }
    }
}


/* 
 * 	Second approaching for lower size dataset on Event And Task
*/


/*
         Map<Id, Date> lastActivityDateMap = new Map<Id, Date>();
        
        for(Task t : [
            SELECT WhoId, LastModifiedDate
            FROM Task
            WHERE WhoId IN :contactIds
        ]){
            if(t.WhoId != null){
                Date d = ((Datetime)t.LastModifiedDate).date();
                if(lastActivityDateMap.get(t.WhoId) == null || d > lastActivityDateMap.get(t.WhoId)){
                    lastActivityDateMap.put(t.WhoId, d);
                }
            }
        }
        
        for(Event e : [
            SELECT WhoId, LastModifiedDate
            FROM Event
            WHERE WhoId IN :contactIds
        ]){
            if(e.WhoId != null){
                Date d = ((Datetime)e.LastModifiedDate).date();
                if(lastActivityDateMap.get(e.WhoId) == null || d > lastActivityDateMap.get(e.WhoId)){
                    lastActivityDateMap.put(e.WhoId, d);
                }
            }
        }

 */