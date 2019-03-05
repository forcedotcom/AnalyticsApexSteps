/**
 * Parser for currency response.
 **/
public with sharing class CurrencyResponse {

    public static void consumeObject(JSONParser parser) {
        Integer depth = 0;
        do {
            JSONToken curr = parser.getCurrentToken();
            if (curr == JSONToken.START_OBJECT || 
                curr == JSONToken.START_ARRAY) {
                depth++;
            } else if (curr == JSONToken.END_OBJECT ||
                curr == JSONToken.END_ARRAY) {
                depth--;
            }
        } while (depth > 0 && parser.nextToken() != null);
    }

    public class Rates {

        public Map<String, Double> rates {get;set;}

        public Rates(JSONParser parser) {
            this.rates = new Map<String, Double>();
            while (parser.nextToken() != JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    // parse this part ourselves since we want the currency responses in a map
                    // vs each a member variable
                    if (parser.nextToken() != JSONToken.VALUE_NULL) {
                        this.rates.put(text, parser.getDoubleValue());
                    }
                }
            }
        }
    }
    
    public String base {get;set;} 
    public Rates rates {get;set;} 

    public CurrencyResponse(JSONParser parser) {
        while (parser.nextToken() != JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != JSONToken.VALUE_NULL) {
                    if (text == 'base') {
                        base = parser.getText();
                    } else if (text == 'rates') {
                        rates = new Rates(parser);
                    } else {
                        System.debug(LoggingLevel.WARN, 'Root consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    public static CurrencyResponse parse(String json) {
        return new CurrencyResponse(System.JSON.createParser(json));
    }

}
