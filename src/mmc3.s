.import nmi_handler, reset_handler, irq_handler

.segment "INESHDR"
  .byt "NES",$1A  ; magic signature
  .byt 2          ; PRG ROM size in 16384 byte units
  .byt 2          ; CHR ROM size in 8192 byte units
  .byt $40        ; mirroring type and mapper number lower nibble
  .byt $00        ; mapper number upper nibble

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler