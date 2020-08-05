*----------------------------------------------------------------------*
*                      Z_CLASS_GET_SET_GENERATOR                       *
*----------------------------------------------------------------------*
* Date   : 04.08.2020                                                  *
* Author : Breno Augusto Cruz Faria                                    *
* Site   : https://github.com/brenoacf                                 *
*----------------------------------------------------------------------*
* Objective : Generate get and sets for ABAP global classes            *
*----------------------------------------------------------------------*
* Program History:                                                     *
* ----------------                                                     *
* Based on the program created by Timo John                            *
* https://wiki.scn.sap.com/wiki/display/Snippets/Generate+GET+and+SET+ *
* methods+for+ABAP+classes                                             *
*----------------------------------------------------------------------*
* TO-DO: - Display results ALV                                         *
*----------------------------------------------------------------------*
*    DATE    |   PERSON   | DESCRIPTION                                *
*----------------------------------------------------------------------*
* 04.08.2020 | Breno Cruz | Initial development                        *
*----------------------------------------------------------------------*

REPORT z_class_get_set_generator.

TABLES: seoclass.

*----------------------------------------------------------------------*
*       CLASS lcl_class_generator DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_class_generator DEFINITION
  CREATE PUBLIC
  FINAL.

  PUBLIC SECTION.
    METHODS: set_parameters
      IMPORTING iv_class_name TYPE seoclsname.

    METHODS: generate.

  PRIVATE SECTION.
    DATA: class_key  TYPE seoclskey,
          class_name TYPE seoclsname.

    METHODS get_class_attributes
      IMPORTING
        iv_class_key    TYPE seoclskey
      RETURNING
        VALUE(r_result) TYPE seoo_attributes_r.

    METHODS create_method_by_attribute
      IMPORTING
        iv_method_name    TYPE seocpdname OPTIONAL
        iv_parameter_name TYPE seosconame OPTIONAL
        io_object         TYPE REF TO if_oo_class_incl_naming
        is_class_attr     TYPE vseoattrib
        iv_pardecltyp     TYPE seopardecl.

    METHODS status_message
      IMPORTING VALUE(iv_message) TYPE string.

    METHODS prevent_ugly_name
      IMPORTING
        iv_method_name  TYPE vseoattrib-cmpname
      RETURNING
        VALUE(r_result) TYPE vseoattrib-cmpname.

ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_designated DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_designated DEFINITION
  CREATE PUBLIC
  FINAL.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING it_data_block TYPE abap_parmbind_tab.
    METHODS populate_method
      RETURNING VALUE(r_result) TYPE seop_source.

  PRIVATE SECTION.
    DATA: s_class_attr TYPE vseoattrib,
          s_parameter  TYPE seos_parameter_r,
          s_method_def TYPE seoo_method_r.
ENDCLASS.

DATA: lo_designated TYPE REF TO lcl_designated.

*----------------------------------------------------------------------*
* Selection Parameters
*----------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1.
PARAMETERS: p_classn TYPE seoclass-clsname MEMORY ID class MATCHCODE OBJECT sfbeclname.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
*       CLASS lcl_class_generator IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_class_generator IMPLEMENTATION.
  METHOD set_parameters.
    me->class_name = iv_class_name.
    me->class_key = iv_class_name.
  ENDMETHOD.

  METHOD generate.
    DATA: lo_object TYPE REF TO if_oo_class_incl_naming.

    IF me->class_key IS INITIAL.
      MESSAGE 'Invalid class' TYPE 'E'.
    ENDIF.

    lo_object ?= cl_oo_include_naming=>get_instance_by_name( CONV seoclsname( me->class_key ) ).

    DATA(lt_class_attributes) = me->get_class_attributes( me->class_key ).

    IF lt_class_attributes IS INITIAL.
      MESSAGE 'No attributes found' TYPE 'E'.
    ENDIF.

    LOOP AT lt_class_attributes ASSIGNING FIELD-SYMBOL(<fs_attr>).
      DATA(lv_method_name) = me->prevent_ugly_name( <fs_attr>-cmpname ).

      me->create_method_by_attribute(
          iv_method_name    = |GET_{ lv_method_name }|
          iv_parameter_name = |R_RESULT|
          io_object         = lo_object
          is_class_attr     = <fs_attr>
          iv_pardecltyp     = seos_pardecltyp_returning
      ).

      me->create_method_by_attribute(
          iv_method_name    = |SET_{ lv_method_name }|
          iv_parameter_name = |IV_{ <fs_attr>-cmpname }|
          io_object         = lo_object
          is_class_attr     = <fs_attr>
          iv_pardecltyp     = seos_pardecltyp_importing
      ).

      me->status_message( iv_message = |Processing attribute: { sy-tabix }| ).
    ENDLOOP.

    MESSAGE 'Complete.' TYPE 'S'.
  ENDMETHOD.

  METHOD status_message.
    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        text   = iv_message
      EXCEPTIONS
        OTHERS = 1.
  ENDMETHOD.

  METHOD get_class_attributes.
    DATA: lt_attributes TYPE seoo_attributes_r.

    IF iv_class_key IS INITIAL.
      RETURN.
    ENDIF.

    CALL FUNCTION 'SEO_CLASS_TYPEINFO_GET'
      EXPORTING
        clskey       = iv_class_key
      IMPORTING
        attributes   = r_result
      EXCEPTIONS
        not_existing = 1
        is_interface = 2
        model_only   = 3
        OTHERS       = 4.
  ENDMETHOD.


  METHOD create_method_by_attribute.
    DATA: lt_parameters     TYPE seos_parameters_r,
          lt_exceptions     TYPE seos_exceptions_r,
          lv_method_name    TYPE seocpdname,
          lv_parameter_name TYPE seosconame.

    IF iv_method_name IS INITIAL.
      lv_method_name = CONV seocpdname( is_class_attr-cmpname ).
    ELSE.
      lv_method_name = iv_method_name.
    ENDIF.

    IF iv_parameter_name IS INITIAL.
      lv_parameter_name = is_class_attr-cmpname.
    ELSE.
      lv_parameter_name = iv_parameter_name.
    ENDIF.

    IF io_object IS NOT BOUND.
      RETURN.
    ENDIF.

    " --- Check Method already exists
    io_object->get_include_by_mtdname(
      EXPORTING
        mtdname                      = lv_method_name
      EXCEPTIONS
        internal_method_not_existing = 1
        OTHERS                       = 2
    ).

    IF sy-subrc IS INITIAL. " Exists - tchau
      RETURN.
    ENDIF.

    CLEAR: lt_parameters, lt_exceptions.

    " --- Create method
    DATA(lo_osral) = cl_osral_oo=>get_repository_obj( me->class_key ).
    lo_osral->set_generator( 'Z_CLASS_GET_SET_GENERATOR' ).

    DATA(ls_parameter) = VALUE seos_parameter_r(
      clsname = me->class_name
      cmpname = lv_method_name
      typtype = is_class_attr-typtype
      type    = is_class_attr-type
      sconame = lv_parameter_name
      pardecltyp = iv_pardecltyp
    ).

    APPEND ls_parameter TO lt_parameters.

    " --- Method Definition
    DATA(ls_method_def) = VALUE seoo_method_r(
      clsname  = me->class_name
      cmpname  = lv_method_name
      state    = seoc_state_implemented " 1
      exposure = seoc_exposure_public " 2
    ).

    lo_osral->method_def_modify(
        i_method     = ls_method_def
        i_parameters = lt_parameters
        i_exceptions = lt_exceptions
    ).

    " --- Method Implementation
    DATA(ls_method_imp) = VALUE seocpdkey(
      clsname = me->class_name
      cpdname = lv_method_name
    ).

    DATA(ls_method_data) = VALUE abap_parmbind_tab(
      ( name = 'CLASS_ATTR' value = REF #( is_class_attr ) )
      ( name = 'PARAMETER'  value = REF #( ls_parameter ) )
      ( name = 'METHOD_DEF' value = REF #( ls_method_def ) )
    ).

    lo_osral->method_imp_create(
      EXPORTING
        i_method     = ls_method_imp
        i_data       = ls_method_data
    ).

    lo_osral->save( ).
  ENDMETHOD.


  METHOD prevent_ugly_name.
    r_result = iv_method_name.

    SEARCH iv_method_name FOR '_'.
    IF sy-subrc IS INITIAL.
      IF sy-fdpos LE 2.
        ADD 1 TO sy-fdpos.
        r_result = iv_method_name+sy-fdpos.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_designated IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_designated IMPLEMENTATION.
  METHOD constructor.
    FIELD-SYMBOLS: <fs_any> TYPE any.

    LOOP AT it_data_block ASSIGNING FIELD-SYMBOL(<data>).
      CASE <data>-name.
        WHEN 'CLASS_ATTR'.
          ASSIGN <data>-value->* TO <fs_any>.
          me->s_class_attr = <fs_any>.
        WHEN 'PARAMETER'.
          ASSIGN <data>-value->* TO <fs_any>.
          me->s_parameter = <fs_any>.
        WHEN 'METHOD_DEF'.
          ASSIGN <data>-value->* TO <fs_any>.
          me->s_method_def = <fs_any>.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD populate_method.
    DATA: lv_code_line TYPE seop_source_line.

    IF s_class_attr IS INITIAL OR
       s_method_def IS INITIAL OR
       s_parameter IS INITIAL.
      RETURN.
    ENDIF.

    IF s_method_def-cmpname(3) EQ 'GET'.
      lv_code_line = |{ s_parameter-sconame } = me->{ s_class_attr-cmpname }.|.
      INSERT lv_code_line INTO r_result INDEX 1.
    ELSEIF s_method_def-cmpname(3) EQ 'SET'.
      lv_code_line = |me->{ s_class_attr-cmpname } = { s_parameter-sconame }.|.
      INSERT lv_code_line INTO r_result INDEX 1.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Forms to be called by cl_osral_oo
*----------------------------------------------------------------------*
FORM set_data USING data_block TYPE abap_parmbind_tab.      "#EC CALLED
  lo_designated = NEW #( data_block ).
ENDFORM.

FORM get_data CHANGING data_block TYPE abap_parmbind_tab.   "#EC CALLED
  " Nothing here
ENDFORM.

FORM method TABLES t_coding TYPE seop_source.               "#EC CALLED
  IF lo_designated IS NOT BOUND.
    EXIT.
  ENDIF.

  t_coding[] = lo_designated->populate_method( ).
ENDFORM.

*----------------------------------------------------------------------*
* Start of the program
*----------------------------------------------------------------------*
INITIALIZATION.
  DATA(lo_class_generator) = NEW lcl_class_generator( ).

START-OF-SELECTION.
  lo_class_generator->set_parameters( p_classn ).
  lo_class_generator->generate( ).
