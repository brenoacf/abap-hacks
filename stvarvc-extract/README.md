# Usage

    DATA: lv_value TYPE rvari_val_255,
          lr_range TYPE ace_generic_range_t,
          lr_range2 TYPE ace_generic_range_t,
          lv_range TYPE ace_generic_range.

    * 1 - Fetching a single parameter
    lv_value = zcl_stvarv_extract=>get_parameter( 'ZK-ER1-WRK-PFAD' ).

    * 2 - Seeking various parameters using the special character pattern
    lr_range = zcl_stvarv_extract=>get_parameters( 'ZI_FORM_MERK_%' ).

    * 3 - Searching for a range of parameters (LOW values)
    REFRESH lr_range.

    lv_range-sign = 'I'.
    lv_range-option = 'EQ'.
    lv_range-low = 'ZS-DSN-KTW-PR1-CMP-SKL'.
    APPEND lv_range TO lr_range.
    lv_range-low = 'ZS-JAHR-LFD-J4'.
    APPEND lv_range TO lr_range.
    lr_range2 = zcl_stvarv_extract=>get_parameters_by_range( lr_range ).

    * 4 - Seeking a "Select Options"
    REFRESH lr_range2.
    lr_range2 = zcl_stvarv_extract=>get_selection_options( '!022GSB000001').