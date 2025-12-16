*&---------------------------------------------------------------------*
*& Include  ZWORK19_001_PBO
*&---------------------------------------------------------------------*

"1) 로컬 클래스 (정의/구현)
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_data_changed
      FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING er_data_changed.
    CLASS-METHODS on_toolbar
      FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object e_interactive.
    CLASS-METHODS on_user_command
      FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD on_toolbar.
  ENDMETHOD.
  METHOD on_data_changed.
  PERFORM handle_data_changed USING er_data_changed.
  ENDMETHOD.
  METHOD on_user_command.
    CASE e_ucomm.
      WHEN 'ZSV'. PERFORM save_to_db.
      WHEN 'ZBK'. LEAVE TO SCREEN 0.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

"2) PBO 모듈 (클래스 ‘뒤’에 둔다)
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  SET TITLEBAR  'TIT1'.

  IF go_dock IS INITIAL.
    CREATE OBJECT go_dock
      EXPORTING repid = sy-repid dynnr = '0100'
                side  = cl_gui_docking_container=>dock_at_left extension = 9999.
    CREATE OBJECT go_grid EXPORTING i_parent = go_dock.

    SET HANDLER lcl_event_handler=>on_data_changed  FOR go_grid.
    SET HANDLER lcl_event_handler=>on_toolbar      FOR go_grid.
    SET HANDLER lcl_event_handler=>on_user_command FOR go_grid.

    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING is_layout = gs_layout
      CHANGING  it_fieldcatalog = gt_fcat  it_outtab = gt_rate.

    CALL METHOD go_grid->register_edit_event
      EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_modified.
  ENDIF.
ENDMODULE.
