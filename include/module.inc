; Navine OS - Kernel module include guard
; When NAVINE_LINK_BUILD is defined, skip duplicate headers and section directives.

%ifndef NAVINE_MODULE_INC
%define NAVINE_MODULE_INC

%macro KERNEL_MODULE_HEADER 0
    %ifndef NAVINE_LINK_BUILD
        [BITS 64]
        %include "constants.inc"
        %include "macros.inc"
    %endif
%endmacro

%macro KERNEL_MODULE_SECTION 1
    %ifndef NAVINE_LINK_BUILD
        section %1
    %endif
%endmacro

%endif
