/**
 * Returns data from a Workday Reporting as a Service report (RaaS)
 * It requires that you setup a Named Credential in Salesforce Setup
 * so you don't have to show the login/pw credentials in the code
 * 
 *
 * @author geoffrothman
 */
@RestResource(urlMapping='/wdraas')
global class WDController {
    
    @HttpPost   
    global static String wdraas() {
        
        // fetch data
        HttpRequest request = new HttpRequest();
        Http http = new Http();
        // make sure this domain is whitelisted in the proxy
        //request.setEndpoint('https://wd2-impl-services1.workday.com/ccx/service/customreport2/salesforce9/sfdc_integration_user1/Einstein-Job-Catalog?format=json');
        request.setEndpoint('callout:WorkdayRaaS_Named_Credential');
        request.setMethod('GET');
        
        try {
            HTTPResponse response = http.send(request);
            JSONParser parser = JSON.createParser(response.getBody());
            
            while (parser.nextToken() != null) {
                
                // find the report entry part of the json
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    
                    WDClass responseObject = (WDClass)parser.readValueAs(WDClass.class);
                    
                    List<ReturnItem> returnItems = new List<ReturnItem>();
                    
                    for (WDClass.Report_Entry currWDRecord  : responseObject.Report_Entry) {
                        returnItems.add(new ReturnItem(1,currWDRecord.Comp_Plan_Id, currWDRecord.Job_Profile, currWDRecord.Job_Code, currWDRecord.Is_Commission_Plan, currWDRecord.Is_Bonus_Plan));
                       }
                    
                    Integer NumItems = returnItems.size();
                    System.debug('Final JSON -->' + JSON.serialize(new PackagedReturnItem(returnItems,NumItems),TRUE));
                    
                    return JSON.serialize(new PackagedReturnItem(returnItems,NumItems),TRUE);
                }
            }
        } catch(Exception exp) {
            System.debug('exception '+exp);
        }
        
        return '';
    }
    
    
    public class ReturnItem {
        
        public Integer Count;
        public String Comp_Plan_Id;
        public String Job_Profile;
        public String Job_Code;
        public String Is_Commission_Plan;
        public String Is_Bonus_Plan;
        
        public ReturnItem(Integer Count, String Comp_Plan_Id, String Job_Profile, String Job_Code, String Is_Commission_Plan, String Is_Bonus_Plan) {
            this.Count = Count;
            this.Comp_Plan_Id = Comp_Plan_Id;
            this.Job_Profile = Job_Profile;
            this.Job_Profile = Job_Code;
            this.Job_Profile = Is_Commission_Plan;
            this.Job_Profile = Is_Bonus_Plan;
        }
    }
    
    public class ReturnMetadata {
        
        public List<String> strings;
        public List<String> numbers;
        public List<String> groups;
        
        public ReturnMetadata(List<String> strings, List<String> numbers, List<String> groups) {
            this.strings = strings;
            this.numbers = numbers;
            this.groups = groups;
        }
    }
    
    public class PackagedReturnItem {
        
        public List<ReturnItem> data;
        public ReturnMetadata metadata;
        public Integer NumItems;
        
        // put the actual values in this method
        public PackagedReturnItem(List<ReturnItem> data, Integer NumItems) {
            this.data = data;
            //this.metadata = new ReturnMetadata(new List<String>{'Comp_Plan_Id','Job_Code','Is_Commission_Plan','Is_Bonus_Plan','Job_Profile'}, new List<String>{'Count'}, new List<String>{'Comp_Plan_Id'});
            this.metadata = new ReturnMetadata(new List<String>{'Comp_Plan_Id','Job_Code','Is_Commission_Plan','Is_Bonus_Plan','Job_Profile'}, new List<String>{'Count'}, new List<String>());
            this.NumItems = NumItems;
        }   
    } 
    
}