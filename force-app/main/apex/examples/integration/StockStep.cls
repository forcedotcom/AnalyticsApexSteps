/**
 * Returns stock prices given a ticker symbol.
 * 
 * query: {
 *     body: {
 *         symbol: "crm"
 *     },
 *     path: "stocks"
 * }
 *
 * @author zuye.zheng
 */
@RestResource(urlMapping='/stocks')
global with sharing class StockStep {

    @HttpPost   
    global static String stocks() {
        ApexStepRequest stepRequest = new ApexStepRequest(new ApexStepRequest.Parameter[]{
            new ApexStepRequest.Parameter('symbol', ApexStepRequest.ParameterType.STRING_PARAM)
        });

        // fetch some stock data
        HttpRequest request = new HttpRequest();
        Http http = new Http();
        // make sure this domain is whitelisted in the proxy
        request.setEndpoint('http://dev.markitondemand.com/MODApis/Api/v2/InteractiveChart/json?parameters=%7B%22Normalized%22%3Afalse%2C%22NumberOfDays%22%3A365%2C%22DataPeriod%22%3A%22Day%22%2C%22Elements%22%3A%5B%7B%22Symbol%22%3A%22' 
            // default to CRM
            + stepRequest.getStringParam('symbol', 'CRM') 
            + '%22%2C%22Type%22%3A%22price%22%2C%22Params%22%3A%5B%22c%22%5D%7D%5D%7D'
        );
        request.setMethod('GET');
        
        try {
            HTTPResponse response = http.send(request);
            JSONParser parser = JSON.createParser(response.getBody());
            
            while (parser.nextToken() != null) {
                // find the stock part of the response
                if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    // parse the stock response and form the response for this controller
                    StockResponse responseObject = (StockResponse)parser.readValueAs(StockResponse.class);
                    List<Map<String, Object>> returnItems = new List<Map<String, Object>>();
                    Integer i = 0;
                    for (String curDate : responseObject.dates) {
                        Map<String, Object> curRow = new Map<String, Object>();
                        curRow.put('date', curDate);
                        curRow.put('value', responseObject.elements.get(0).dataSeries.close.values.get(i++));
                        returnItems.add(curRow);
                    }

                    // return the serialized response
                    return JSON.serialize(new ApexStepResponse(returnItems));
                }
            }
        } catch(Exception exp) {
            System.debug('exception '+exp);
        }
        
        return '';
    }

    /**
    * Bunch of stuff to parse the stock response.
    **/
    private class StockResponse {
        
        private List<String> dates;
        private List<StockResponseElement> elements;
        
        public StockResponse(List<String> dates, List<StockResponseElement> elements) {
            this.dates = dates;
            this.elements = elements;
        }
        
    }
    
    private class StockResponseElement {
    
        private String type;
        private StockResponseDataSeries dataSeries;
        
        public StockResponseElement(String type, StockResponseDataSeries dataSeries) {
            this.type = type;
            this.dataSeries = dataSeries;
        }
    
    }
    
    private class StockResponseDataSeries {
    
        private StockResponseDataSeriesValues close;
        
        public StockResponseDataSeries(StockResponseDataSeriesValues close) {
            this.close = close;
        }
    
    }
    
    private class StockResponseDataSeriesValues {
    
        private List<Double> values;
        
        public StockResponseDataSeriesValues(List<Double> values) {
            this.values = values;
        }
    
    }
    
}