/**
 * Transposes a table of data.
 *
 * Lets say you created an awesome YOY comparison using the compare table with each year being its own column:
 * Region | 1987 | 1988 | 1989 | 1990         
 * US     | 10   | 20   | 30   | 40
 * CAD    | 60   | 50   | 40   | 30
 *
 * However, to show this as a trended line or bar stacked by region, this data needs to be transposed to look like:
 * Year | US  | CAD
 * 1987 | 10  | 60
 * 1988 | 20  | 50
 * 1989 | 30  | 40
 * 1990 | 40  | 30
 *
 * The expected query shape:
 * query: {
 *    body: {
 *        // select the data to transpose using bindings
 *        data: "{{row(original.result, [], [\"Region\", \"1987\", \"1988\", \"1989\", \"1990\"]).asObject()}}",
 *        // tell us about the data since we lose column names in bindings
 *        columns: ["Region", "1987", "1988", "1989", "1990"],
 *        // column to transpose by 
 *        transposedColumn: "Region",
 *        // name of the transposed column names
 *        grouping: "Year"
 *    }
 * }
 *
 * @author zuye.zheng
 **/
@RestResource(urlMapping='/transpose')
global with sharing class TransposeStep {

    @HttpPost  
    global static String transpose() {
        // tell the request parser what to expect
        ApexStepRequest stepRequest = new ApexStepRequest(new ApexStepRequest.Parameter[]{
            new ApexStepRequest.Parameter('data', ApexStepRequest.ParameterType.DATA_PARAM),
            new ApexStepRequest.Parameter('columns', ApexStepRequest.ParameterType.STRING_LIST_PARAM),
            new ApexStepRequest.Parameter('transposedColumn', ApexStepRequest.ParameterType.STRING_PARAM),
            new ApexStepRequest.Parameter('grouping', ApexStepRequest.ParameterType.STRING_PARAM)
        });

        // graph the parameters we need from the request
        List<Map<String, Object>> data = stepRequest.getMappedData('data', 'columns');
        List<String> columns = stepRequest.getStringListParam('columns');
        String transposedColumn = stepRequest.getStringParam('transposedColumn');
        String grouping = stepRequest.getStringParam('grouping');

        // some light error checking
        if (columns.indexof(transposedColumn) == -1) {
            throw new TransposeStepException('Transposed column not found in columns.');
        }

        List<Map<String, Object>> transposedData = new List<Map<String, Object>>();
        for (String curColumn : columns) {
            // skip the column we are transposing by, it will become column headers (aka keys for the row map)
            if (curColumn.equals(transposedColumn)) continue;

            // create a new transposed row starting with the current column name as a row value
            Map<String, Object> transposedRow = new Map<String, Object>();
            transposedRow.put(grouping, curColumn);

            // tranpose the remaining values in the column into a row
            for (Map<String, Object> curRow : data) {
                transposedRow.put(String.valueOf(curRow.get(transposedColumn)), curRow.get(curColumn));
            }
            transposedData.add(transposedRow);
        }

        return JSON.serialize(new ApexStepResponse(transposedData, new String[]{grouping}));
    }

    public class TransposeStepException extends Exception {}

}
