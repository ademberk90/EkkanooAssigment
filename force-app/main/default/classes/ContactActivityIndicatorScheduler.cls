public class ContactActivityIndicatorScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ContactActivityIndicatorBatch(), 2000);
    }
}


/*
 
 * 	Schedulable
	String cron = '0 0 0 * * ?'; // Every date at 00:00
	System.schedule('Daily Contact Activity Indicator Update', cron, new ContactActivityIndicatorScheduler());


 * Execute once
   ContactActivityIndicatorScheduler sch = new ContactActivityIndicatorScheduler();
   sch.execute(null);

*/