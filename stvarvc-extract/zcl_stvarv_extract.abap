CLASS zcl_stvarv_extract DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Get a single parameter value from STVARV using a name
    "! @parameter iv_parameter_name           | Parameter name from STVARV
    "! @parameter r_result                    | Result like VALUE from STVARV
    CLASS-METHODS get_parameter
      IMPORTING
        iv_parameter_name TYPE rvari_vnam
      RETURNING
        VALUE(r_result)   TYPE rvari_val_255.

    "! Get parameters like RANGE from a single value
    "! It's possible to use % signal to use in a internal select from STVARV
    "! The parameter high of RANGE comes with the name of the parameter and
    "! the low with the value
    "! @parameter iv_parameter_name           | Parameter name using % signal
    "! @parameter r_result                    | Result RANGE with values from STVARV
    CLASS-METHODS get_parameters
      IMPORTING
        iv_parameter_name TYPE rvari_vnam
      RETURNING
        VALUE(r_result)   TYPE ace_generic_range_t.

    "! Get a RANGE of values from STVARV using a RANGE of names
    "! The parameter high of RANGE comes with the name of the parameter and
    "! the low with the value
    "! @parameter iv_parameter_name           | Range of names parameters
    "! @parameter r_result                    | Result RANGE with values from STVARV
    CLASS-METHODS get_parameters_by_range
      IMPORTING
        it_parameter_name TYPE ace_generic_range_t
      RETURNING
        VALUE(r_result)   TYPE ace_generic_range_t.

    "! Get select options from STVARV using a single value
    "! @parameter iv_parameter_name           | Parameter name from STVARV
    "! @parameter r_result                    | Result RANGE with values from STVARV
    CLASS-METHODS get_selection_options
      IMPORTING
        iv_parameter_name TYPE rvari_vnam
      RETURNING
        VALUE(r_result)   TYPE ace_generic_range_t.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_stvarv_extract IMPLEMENTATION.

  METHOD get_parameter.
    IF iv_parameter_name IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE low
      INTO r_result
      FROM tvarvc
     WHERE name EQ iv_parameter_name
       AND type EQ 'P'.
  ENDMETHOD.

  METHOD get_parameters.
    DATA: lr_range  TYPE ace_generic_range,
          lt_tvarvc TYPE STANDARD TABLE OF tvarvc.

    IF iv_parameter_name IS INITIAL.
      RETURN.
    ENDIF.

    IF iv_parameter_name CA '%'.
      SELECT *
        INTO TABLE lt_tvarvc
        FROM tvarvc
       WHERE name LIKE iv_parameter_name
         AND type EQ 'P'.
    ELSE.
      SELECT *
        INTO TABLE lt_tvarvc
        FROM tvarvc
       WHERE name EQ iv_parameter_name
         AND type EQ 'P'.
    ENDIF.

    IF lt_tvarvc IS INITIAL.
      RETURN.
    ENDIF.

    IF lines( lt_tvarvc ) EQ 1.
      READ TABLE lt_tvarvc ASSIGNING FIELD-SYMBOL(<fs_value>) INDEX 1.
      lr_range-high = <fs_value>-high.
      lr_range-low = <fs_value>-low.
      lr_range-option = <fs_value>-opti.
      lr_range-sign = <fs_value>-sign.
      APPEND lr_range TO r_result.
    ELSE.
      LOOP AT lt_tvarvc ASSIGNING FIELD-SYMBOL(<fs_value2>).
        CLEAR lr_range.
        lr_range-high = <fs_value2>-name.
        lr_range-low = <fs_value2>-low.
        APPEND lr_range TO r_result.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD get_parameters_by_range.
    DATA: lr_range  TYPE ace_generic_range,
          lt_tvarvc TYPE STANDARD TABLE OF tvarvc.

    IF it_parameter_name IS INITIAL.
      RETURN.
    ENDIF.

    SELECT *
      INTO TABLE lt_tvarvc
      FROM tvarvc
     WHERE name IN it_parameter_name
       AND type EQ 'P'.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_tvarvc ASSIGNING FIELD-SYMBOL(<fs_value>).
      CLEAR lr_range.
      lr_range-high = <fs_value>-name.
      lr_range-low = <fs_value>-low.
      APPEND lr_range TO r_result.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_selection_options.
    DATA: lt_tvarvc TYPE STANDARD TABLE OF tvarvc,
          lw_range  TYPE ace_generic_range.

    IF iv_parameter_name IS INITIAL.
      RETURN.
    ENDIF.

    SELECT *
      INTO TABLE lt_tvarvc
      FROM tvarvc
     WHERE name EQ iv_parameter_name
       AND type EQ 'S'.

    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_tvarvc ASSIGNING FIELD-SYMBOL(<fs_value>).
      CLEAR lw_range.
      lw_range-sign = <fs_value>-sign.
      lw_range-option = <fs_value>-opti.
      lw_range-low = <fs_value>-low.
      lw_range-high = <fs_value>-high.
      APPEND lw_range TO r_result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
