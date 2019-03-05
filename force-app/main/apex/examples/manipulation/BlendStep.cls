/**
 * Blends or "joins" 2 tables of data.
 *
 * If you have tables from two different steps from different sources that can't natively be joined you can use this to
 * blend into a single result set. Remember that this will only blend data returned to the UI from the original queries
 * and performance will be constrained by the size of these results.
 *
 * This supports 2 methods for blending, by index which will just join row by row, or a "left" join by provided keys.
 *
 * Lets say we have a result set from SAQL of:
 * Year | US  | CAD
 * 1987 | 10  | 60
 * 1988 | 20  | 50
 * 1989 | 30  | 40
 * 1990 | 40  | 30
 *
 * And another result set (from SOQL, static step, etc.) that we want to augment the original (left) table with:
 * Year | Quota
 * 1987 | 30
 * --- note missing right values are also supported since a left join
 * 1989 | 35
 * 1990 | 40
 *
 * The expected query shape:
 * query: {
 *     body: {
 *         // select the left table
 *         left: "{{row(left.result, [], [\"Year\", \"US\", \"CAD\"]).asObject()}}",
 *         leftColumns: ["Year", "US", "CAD"],
 *         // we are joining by year, left and right keys are not required when blending by index
 *         leftKey: "Year",
 *         right: "{{row(right.result, [], [\"Year\", \"Quota\"]).asObject()}}",
 *         rightColumns: ["Year", "Quota"],
 *         rightKey: "Year",
 *         blendType: "left"
 *     }
 * }
 *
 * @author zuye.zheng
 **/
@RestResource(urlMapping='/blend')
global with sharing class BlendStep {

    @HttpPost  
    global static String blend() {
        // tell the request parser what to expect
        ApexStepRequest stepRequest = new ApexStepRequest(new ApexStepRequest.Parameter[]{
            new ApexStepRequest.Parameter('left', ApexStepRequest.ParameterType.DATA_PARAM),
            new ApexStepRequest.Parameter('leftColumns', ApexStepRequest.ParameterType.STRING_LIST_PARAM),
            new ApexStepRequest.Parameter('leftKey', ApexStepRequest.ParameterType.STRING_PARAM),
            new ApexStepRequest.Parameter('right', ApexStepRequest.ParameterType.DATA_PARAM),
            new ApexStepRequest.Parameter('rightColumns', ApexStepRequest.ParameterType.STRING_LIST_PARAM),
            new ApexStepRequest.Parameter('rightKey', ApexStepRequest.ParameterType.STRING_PARAM),
            new ApexStepRequest.Parameter('blendType', ApexStepRequest.ParameterType.STRING_PARAM),
            new ApexStepRequest.Parameter('groups', ApexStepRequest.ParameterType.STRING_LIST_PARAM)
        });

        // get the left and right tables to blend
        List<Map<String, Object>> left = stepRequest.getMappedData('left', 'leftColumns');
        List<Map<String, Object>> right = stepRequest.getMappedData('right', 'rightColumns');

        String blendType = stepRequest.getStringParam('blendType');
        List<String> groups;
        if (blendType.equals('index')) {
            // we'll blend as much as we can since SAQL does not enforce all rows to have the same values
            Integer rowsToBlend = Math.min(left.size(), right.size());
            for (Integer i=0; i<rowsToBlend; i++) {
                // merge all the values from the right table into the left
                left.get(i).putAll(right.get(i));
            }

            groups = stepRequest.getStringListParam('groups');
        } else if (blendType.equals('left')) {
            // left join requires valid left and right keys
            Set<String> leftColumns = new Set<String>(stepRequest.getStringListParam('leftColumns'));
            String leftKey = stepRequest.getStringParam('leftKey');
            if (!leftColumns.contains(leftKey)) {
                throw new BlendStepException('Left key not found.');
            } 

            Set<String> rightColumns = new Set<String>(stepRequest.getStringListParam('rightColumns'));
            String rightKey = stepRequest.getStringParam('rightKey');
            if (!rightColumns.contains(rightKey)) {
                throw new BlendStepException('Right key not found.');
            }

            // put the right table into map to join with
            Map<String, Map<String, Object>> rightMapped = new Map<String, Map<String, Object>>();
            for (Map<String, Object> curRow : right) {
                rightMapped.put(String.valueOf(curRow.get(rightKey)), curRow);
                // right key will be duplicated when joined so remove it
                curRow.remove(rightKey);
            }

            // join into the left table
            for (Map<String, Object> curRow : left) {
                String leftKeyValue = String.valueOf(curRow.get(leftKey));
                if (rightMapped.containsKey(leftKeyValue)) {
                    curRow.putAll(rightMapped.get(leftKeyValue));
                }
            }

            // default groups to the left key used to join
            groups = stepRequest.getStringListParam('groups', new String[]{leftKey});
        } else {
            throw new BlendStepException('Blend type must be index or left.');
        }

        return JSON.serialize(new ApexStepResponse(left, groups));
    }

    public class BlendStepException extends Exception {}

}
