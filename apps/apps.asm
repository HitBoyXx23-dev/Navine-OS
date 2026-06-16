; Navine OS - Application Stub Framework

[BITS 64]

%macro APP_ENTRY 1
global %1_main
%1_main:
    ret
%endmacro

APP_ENTRY app_files
APP_ENTRY app_text
APP_ENTRY app_browser
APP_ENTRY app_photos
APP_ENTRY app_music
APP_ENTRY app_settings
APP_ENTRY app_taskmgr
APP_ENTRY app_calculator
APP_ENTRY app_clock
APP_ENTRY app_terminal
