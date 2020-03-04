# Usage

Import zcl_stvarv_extract.abap class to your system through SE24 or using SAPLINK with the nugg file. Another way is to create a local class and import through SE24. More information about import, click [here](https://brenoacf.github.io/sap/abap/2020/03/02/1-Abap-Hacks-STVARV.html) (in portuguese only).

After that you can use the options as shown below.

Enjoy!

```abap
"! This code show how to use the zcl_stvarv_extract class.

DATA: lv_value        TYPE rvari_val_255,
      lr_range        TYPE ace_generic_range_t,
      lv_range        TYPE ace_generic_range,
      lr_range_result TYPE ace_generic_range_t.

* 1 - Fetching a single parameter
lv_value = zcl_stvarv_extract=>get_parameter( 'Z_SINGLE_PARAM' ).

* 2 - Seeking various parameters using the special character pattern
lr_range = zcl_stvarv_extract=>get_parameters( 'Z_WERKS_%' ).

* 3 - Searching for a range of parameters (LOW values)
REFRESH lr_range.
lv_range-sign = 'I'.
lv_range-option = 'EQ'.

lv_range-low = 'Z_BUKRS'.
APPEND lv_range TO lr_range.

lv_range-low = 'Z_WERDS'.
APPEND lv_range TO lr_range.

lv_range-low = 'Z_GJAHR'.
APPEND lv_range TO lr_range.

lr_range_result = zcl_stvarv_extract=>get_parameters_by_range( lr_range ).

* 4 - Seeking a "Select Options"
REFRESH lr_range_result.
lr_range_result = zcl_stvarv_extract=>get_selection_options( 'Z_SELECTION_PARAM').
```
