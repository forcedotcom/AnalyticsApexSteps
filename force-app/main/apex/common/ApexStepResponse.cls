/**
 * Helps serialize data with full or partial metadata to be consumed by the and Apex Step.
 *
 * Almost everything can be inferred except for which columns are the "groups" which helps EA dashboards with
 * selections and visualizing the data.
 *
 * @author zuye.zheng
 **/
public with sharing class ApexStepResponse {
    
    public final List<Map<String, Object>> data;
    public final Metadata metadata;
    
    public ApexStepResponse(List<Map<String, Object>> data, Metadata metadata) {
        this.data = data;
        this.metadata = metadata;
    }
    
    /**
     * Build metadata from sampling the first row of data. 
     **/
    public ApexStepResponse(List<Map<String, Object>> data, List<String> groups) {
        this.data = data;
        Set<String> strings = new Set<String>();
        Set<String> numbers = new Set<String>();

        // sample the first 10 rows to figure out the columns to account for nulls
        Integer i = 0;
        for (Map<String, Object> curRow : data) {
            for (String curColumn : curRow.keySet()) {
                // make sure we only put it in one bucket even if the data is messed up
                if (!numbers.contains(curColumn) && !strings.contains(curColumn)) {
                    if (curRow.get(curColumn) instanceof Double) {
                        numbers.add(curColumn);
                    } else {
                        strings.add(curColumn);
                    }
                }
            }

            if (++i >= 10) {
                break;
            }
        }
        
        this.metadata = new Metadata(new List<String>(strings), new List<String>(numbers), groups);
    }
    
    /**
     * Build metadata from sampling the first row of data, no groups.
     **/
    public ApexStepResponse(List<Map<String, Object>> data) { 
        this(data, new List<String>());   
    }

    public class Metadata {
    
        public List<String> strings;
        public List<String> numbers;
        public List<String> groups;
        
        public Metadata(List<String> strings, List<String> numbers, List<String> groups) {
            this.strings = strings;
            this.numbers = numbers;
            this.groups = groups;
        }
    
    }
    
}
