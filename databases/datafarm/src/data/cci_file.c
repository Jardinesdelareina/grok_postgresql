#include "postgres.h"
#include "fmgr.h"
#include <math.h>
#include "utils/array.h"

PG_MODULE_MAGIC;
PG_FUNCTION_INFO_V1(cci_func);

Datum cci_func(PG_FUNCTION_ARGS) 
{
    ArrayType *arr = PG_GETARG_ARRAYTYPE_P(0);
    int len = ArrayGetNItems(ARR_NDIM(arr), ARR_DIMS(arr));
    float8* prices = (float8*) ARR_DATA_PTR(arr);
    int period = PG_GETARG_INT32(1);

    if (period <= 0 || len < period) {
        PG_RETURN_FLOAT8(0.0);
    }

    float8 sum = 0.0;
    for (int i = 0; i < period; i++) {
        sum += prices[i];
    }
    float8 sma = sum / period;
        
    float8 mean_deviation = 0.0;
    for (int i = 0; i < period; i++) {
        mean_deviation += fabs(prices[i] - sma);
    }
    mean_deviation /= period;

    float8 cci_value = (prices[period - 1] - sma) / (0.015 * mean_deviation);

    PG_RETURN_FLOAT8(cci_value);
}