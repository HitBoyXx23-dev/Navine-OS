; Navine OS - Paint framebuffer before full driver init

[BITS 64]

%include "constants.inc"

global early_framebuffer_paint

section .text
early_framebuffer_paint:
    ret
