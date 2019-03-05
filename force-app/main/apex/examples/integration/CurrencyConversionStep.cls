/**
 * Converts a column of numbers from one currency to another. Step should be in the form (assuming data is coming from 
 * an Apex Stock Step):
 * 
 * query: {
 *     body: {
 *         // pipe data in from any step using bindings
 *         data: "{{row(StockData.result, [], [\"date\", \"value\"]).asObject()}}",
 *         targetColumn: "value",
 *         columns: ["date", "value"],
 *         baseCurrency: "USD",
 *         targetCurrency: "CAD"
 *     },
 *     path: "currency"
 * }
 *
 * @author zuye.zheng
 */
@RestResource(urlMapping='/currency')
global with sharing class CurrencyConversionStep {

    @HttpPost   
    global static String currency() {
        // tell the request parser what to expect
        ApexStepRequest stepRequest = new ApexStepRequest(new ApexStepRequest.Parameter[]{
            new ApexStepRequest.Parameter('data', ApexStepRequest.ParameterType.DATA_PARAM),
            new ApexStepRequest.Parameter('baseCurrency', ApexStepRequest.ParameterType.STRING_PARAM),
            new ApexStepRequest.Parameter('targetCurrency', ApexStepRequest.ParameterType.STRING_PARAM),
            new ApexStepRequest.Parameter('targetColumn', ApexStepRequest.ParameterType.STRING_PARAM),
            new ApexStepRequest.Parameter('columns', ApexStepRequest.ParameterType.STRING_LIST_PARAM)
        });
     
        // fetch the current currency rates for the target currency with USD as base
        HttpRequest request = new HttpRequest();
        Http http = new Http();
        request.setEndpoint('https://api.exchangeratesapi.io/latest?base=' + stepRequest.getStringParam('baseCurrency', 'USD') );
        request.setMethod('GET');

        HTTPResponse response = http.send(request);
        CurrencyResponse currencyResponse = new CurrencyResponse(JSON.createParser(response.getBody()));

        // convert the values specified in the target column
        Double conversionRate = currencyResponse.rates.rates.get(stepRequest.getStringParam('targetCurrency', 'CAD'));
        List<Map<String, Object>> data = stepRequest.getMappedData('data', 'columns');
        String targetColumn = stepRequest.getStringParam('targetColumn');
        for (Map<String, Object> curRow : data) {
            curRow.put(targetColumn, (Double)curRow.get(targetColumn) * conversionRate);
        }

        return JSON.serialize(new ApexStepResponse(data));
    }
    
}