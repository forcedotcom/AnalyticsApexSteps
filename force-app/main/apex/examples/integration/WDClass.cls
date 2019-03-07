/**
 * Returns data from a Workday Reporting as a Service report (RaaS)
 * It requires that you setup a Named Credential in Salesforce Setup
 * so you don't have to show the login/pw credentials in the code
 * 
 *
 * @author geoffrothman
 */

public class WDClass {
    
    public List<Report_Entry> Report_Entry;
    
    public class Report_Entry {
        public String Comp_Plan_Id;
        public String Is_Bonus_Plan;
        public String Is_Commission_Plan;
        public String Job_Code;
        public String Job_Profile;
        public List<Comp_Eligibility_Rules> Comp_Eligibility_Rules;
        public List<Comp_Grades> Comp_Grades;
        public String Multi_Comp_Plan_Ref_ID;
    }

    public class Comp_Eligibility_Rules {
        public String Comp_Rule_Name;
        public String Is_Base_Salary_Only;
        public String Is_Hybrid_Plan;
    }

    public class Comp_Grades {
        public String Comp_Grade_Profiles;
    }

}