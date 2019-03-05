/**
 * Help parse Apex Step requests, construct one by providing a schema such as:
 *
 * ApexStepRequest stepRequest = new ApexStepRequest(new ApexStepRequest.Parameter[]{
 *    // data passed to the apex step via bindings
 *    new ApexStepRequest.Parameter('data', ApexStepRequest.ParameterType.DATA_PARAM),
 *    // since we lose the concept of columns with bindings, we can take an array of strings to help tell us what each
 *    // column represents
 *    new ApexStepRequest.Parameter('columns', ApexStepRequest.ParameterType.STRING_LIST_PARAM),
 *    // simple strings and numbers
 *    new ApexStepRequest.Parameter('someText', ApexStepRequest.ParameterType.STRING_PARAM),
 *    new ApexStepRequest.Parameter('someNumber', ApexStepRequest.ParameterType.DOUBLE_PARAM)
 * });
 * 
 * @author zuye.zheng
 **/
public with sharing class ApexStepRequest {

    private final Map<String, Parameter> parameters;
    private final Map<Parameter, Object> values;
    
    public ApexStepRequest(List<Parameter> parameters) {
        this(RestContext.request.requestBody.toString(), parameters);
    }
    
    public ApexStepRequest(String request, List<Parameter> parameters) {
        this.parameters = new Map<String, Parameter>();
        for (Parameter curParameter : parameters) {
            this.parameters.put(curParameter.getName(), curParameter);
        }
        
        this.values = new Map<Parameter, Object>();
        
        JSONParser requestParser = JSON.createParser(request);
        while (requestParser.nextToken() != null) {
            if (requestParser.getCurrentToken() == JSONToken.FIELD_NAME) {
                // parse out configured parameters
                Parameter curParameter = this.parameters.get(requestParser.getText());
                if (curParameter != null) {
                    if (curParameter.getType() == ParameterType.STRING_PARAM) {
                        requestParser.nextToken();
                        this.values.put(curParameter, requestParser.getText());
                    } else if (curParameter.getType() == ParameterType.DOUBLE_PARAM) {
                        requestParser.nextToken();
                        this.values.put(curParameter, requestParser.getDoubleValue());
                    } else if (curParameter.getType() == ParameterType.STRING_LIST_PARAM) {
                        this.values.put(curParameter, parseStringList(requestParser));
                    } else if (curParameter.getType() == ParameterType.DATA_PARAM) {
                        if (requestParser.nextToken() == JSONToken.START_ARRAY) {
                            List<List<Object>> data = new List<List<Object>>();
                            while (requestParser.nextToken() == JSONToken.START_ARRAY) {
                                data.add(parseRow(requestParser));
                            }
                            this.values.put(curParameter, data);
                        }
                    }
                }
            }
        }
    }

    /**
     * Poorman's Java generics.
     **/    
    public String getStringParam(String name) {
        Parameter parameter = this.parameters.get(name);
        if (parameter == null || parameter.getType() != ParameterType.STRING_PARAM) {
            return null;
        }
        
        return (String) this.values.get(parameter);
    }

    public String getStringParam(String name, String defaultValue) {
        String value = getStringParam(name);
        if (value == null) {
            return defaultValue;
        }
            
        return value;
    }
    
    public Double getDoubleParam(String name) {
        Parameter parameter = this.parameters.get(name);
        if (parameter == null || parameter.getType() != ParameterType.DOUBLE_PARAM) {
            return null;
        }
        
        return (Double) this.values.get(parameter);
    }

    public Double getDoubleParam(String name, Double defaultValue) {
        Double value = getDoubleParam(name);
        if (value == null) {
            return defaultValue;
        }
        
        return value;
    }
    
    public List<String> getStringListParam(String name) {
        Parameter parameter = this.parameters.get(name);
        if (parameter == null || parameter.getType() != ParameterType.STRING_LIST_PARAM) {
            return null;
        }
        
        return (List<String>) this.values.get(parameter);
    }

    public List<String> getStringListParam(String name, List<String> defaultValue) {
        List<String> value = getStringListParam(name);
        if (value == null) {
            return defaultValue;
        }
        
        return value;
    }

    public List<List<Object>> getDataParam(String name) {
        Parameter parameter = this.parameters.get(name);
        if (parameter == null || parameter.getType() != ParameterType.DATA_PARAM) {
            return null;
        }
        
        return (List<List<Object>>) this.values.get(parameter);
    }
    
    /**
     * Return a new copy of the data in a list of maps given the string list param that stores column order.
     **/
    public List<Map<String, Object>> getMappedData(String dataParam, String columnsParam) {
        // see if we need to form mapped data
        List<Map<String, Object>> mappedData = new List<Map<String, Object>>();
        List<String> columns = getStringListParam(columnsParam);
        if (columns != null) {
            List<List<Object>> data = getDataParam(dataParam);
            for (List<Object> curRow : data) {
                Map<String, Object> newRow = new Map<String, Object>();
                
                Integer i = 0;
                for (String curColumn : columns) {
                    newRow.put(curColumn, curRow.get(i++)); 
                }
                
                mappedData.add(newRow);
            }
        }
        return mappedData;
    }
    
    private static List<Object> parseRow(JSONParser requestParser) {
        List<Object> row = new List<Object>();
    
        while (requestParser.nextToken() != JSONToken.END_ARRAY) {
            if (requestParser.getCurrentToken() == JSONToken.VALUE_NUMBER_FLOAT || requestParser.getCurrentToken() == JSONToken.VALUE_NUMBER_INT) {
                row.add(requestParser.getDoubleValue());
            } else {
                row.add(requestParser.getText());
            }
        }
        
        return row;
    }
    
    private static List<String> parseStringList(JSONParser requestParser) {
        if (requestParser.nextToken() != JSONToken.START_ARRAY) {
            throw new ParseException('Not an array.');
        }
    
        List<String> stringList = new List<String>();
        while (requestParser.nextToken() != JSONToken.END_ARRAY) {
            if (requestParser.getCurrentToken() == JSONToken.VALUE_STRING) {
                stringList.add(requestParser.getText());
            }
        }
        
        return stringList;
    }

    /**
     * Define a request parameter for parsing. 
     **/
    public class Parameter {
        
        private final String name;
        private final ParameterType type;
        
        public Parameter(String name, ParameterType type) {
            this.name = name;
            this.type = type;
        }
        
        public String getName() {
            return this.name;
        }
        
        public ParameterType getType() {
            return this.type;
        }
        
    }
    
    public enum ParameterType {
        
        STRING_PARAM, DOUBLE_PARAM, STRING_LIST_PARAM, DATA_PARAM
           
    }
    
    public class ParseException extends Exception {}
    
}

