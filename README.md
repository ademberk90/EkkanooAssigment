# Salesforce DX Project – Contact Activity Indicator

This project is developed to implement and manage the **Contact Activity Indicator** batch class in a Salesforce environment. It is built using **Salesforce DX (SFDX)** and **VS Code**.  The main codes are located under: force-app/main/default/classes/

---

## 🎯 About Project 

Business owner want to maintain an **Activity Indicator** for each Contact, so that he can easily track how recently the Contact has had any engagement (Task/Event).

**Rules for `Activity_Indicator__c`:**

- If the Contact’s related Account has **Active = "No"**, then `Activity_Indicator__c = 0` (overrides all other rules).  
- Otherwise, the indicator is based on the **most recently modified Task/Event** linked to the Contact:
  - 0–90 days → `Activity_Indicator__c = 1`
  - 91–180 days → `Activity_Indicator__c = 2`
  - 181–270 days → `Activity_Indicator__c = 3`
  - 271–360 days → `Activity_Indicator__c = 4`
  - >360 days → `Activity_Indicator__c = 5`  
- If the Contact has **no Task/Event records**, set `Activity_Indicator__c = -1`.

---

## 📝 Considerations

- The org may have **50,000+ Contacts**, so the solution must be **scalable** and handle bulk processing efficiently.  
- `Activity_Indicator__c` must be **updated daily** to reflect the latest activity.  
- Use **Batch Apex with Database.Stateful** to handle large datasets and retain state across chunks.  
- Implement **chunk-level error handling** so that errors on some records do not stop the entire batch.

---

## ✅ Acceptance Criteria

- Contact with an **Active Account** and a Task modified **45 days ago** → indicator = 1  
- Contact with an **Active Account** and a Task modified **120 days ago** → indicator = 2  
- Contact with an **Active Account** and **no Task/Event** → indicator = -1  
- Contact with an **Inactive Account** → indicator = 0 regardless of activities  
- Contact with an **Active Account** and a Task last modified **400 days ago** → indicator = 5  
- Updates run **daily**, ensuring all Contacts reflect the latest correct indicator values.  
- Supports **>50k Contacts** without errors or performance issues.

