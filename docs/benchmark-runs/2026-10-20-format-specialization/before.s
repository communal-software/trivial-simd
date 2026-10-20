	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 15, 0	sdk_version 26, 2
	.globl	_ts_encoded_matmul              ; -- Begin function ts_encoded_matmul
	.p2align	2
_ts_encoded_matmul:                     ; @ts_encoded_matmul
	.cfi_startproc
; %bb.0:
	mov	w8, #1                          ; =0x1
	cmp	w0, #1
	b.hi	LBB0_20
; %bb.1:
	orr	x9, x2, x1
	orr	x9, x9, x3
	tbnz	x9, #63, LBB0_20
; %bb.2:
	cmp	x5, x3
	b.lt	LBB0_20
; %bb.3:
	cmp	x7, x3
	b.lt	LBB0_20
; %bb.4:
	sub	sp, sp, #32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	add	x29, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	ldr	x9, [x29, #24]
	cmp	x9, x2
	b.lt	LBB0_19
; %bb.5:
	cbz	x2, LBB0_10
; %bb.6:
	cbz	x3, LBB0_10
; %bb.7:
	mov	x8, #4611686018427387903        ; =0x3fffffffffffffff
	cmp	x3, x8
	b.gt	LBB0_18
; %bb.8:
	cbz	x5, LBB0_10
; %bb.9:
	sub	x8, x2, #1
	mov	x10, #4611686018427387903       ; =0x3fffffffffffffff
	sub	x10, x10, x3
	sdiv	x10, x10, x5
	cmp	x8, x10
	b.gt	LBB0_18
LBB0_10:
	cbz	x1, LBB0_15
; %bb.11:
	cbz	x3, LBB0_15
; %bb.12:
	mov	x8, #2305843009213693951        ; =0x1fffffffffffffff
	cmp	x3, x8
	b.gt	LBB0_18
; %bb.13:
	cbz	x7, LBB0_15
; %bb.14:
	sub	x8, x1, #1
	mov	x10, #2305843009213693951       ; =0x1fffffffffffffff
	sub	x10, x10, x3
	sdiv	x10, x10, x7
	cmp	x8, x10
	b.gt	LBB0_18
LBB0_15:
	mov	w8, #0                          ; =0x0
	cbz	x1, LBB0_19
; %bb.16:
	cbz	x2, LBB0_19
; %bb.17:
	mov	x8, #2305843009213693951        ; =0x1fffffffffffffff
	cmp	x2, x8
	b.le	LBB0_21
LBB0_18:
	mov	w8, #1                          ; =0x1
LBB0_19:
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32
LBB0_20:
	mov	x0, x8
	ret
LBB0_21:
	ldr	x10, [x29, #16]
	cbz	x9, LBB0_24
; %bb.22:
	mov	w8, #1                          ; =0x1
	cbz	x10, LBB0_19
; %bb.23:
	sub	x11, x1, #1
	mov	x12, #2305843009213693951       ; =0x1fffffffffffffff
	sub	x12, x12, x2
	sdiv	x12, x12, x9
	cmp	x11, x12
	b.le	LBB0_25
	b	LBB0_19
LBB0_24:
	cbz	x10, LBB0_18
LBB0_25:
	cbz	x3, LBB0_28
; %bb.26:
	mov	w8, #1                          ; =0x1
	cbz	x4, LBB0_19
; %bb.27:
	cbz	x6, LBB0_19
LBB0_28:
	cbz	w0, LBB0_30
; %bb.29:
	; InlineAsm Start
	mrs	x8, FPCR
	; InlineAsm End
	mov	w11, #67633152                  ; =0x4080000
	tst	x8, x11
	mov	w8, #2                          ; =0x2
	csel	w0, w8, w0, eq
LBB0_30:
Lloh0:
	adrp	x8, _encoded_tile_batch@PAGE
Lloh1:
	add	x8, x8, _encoded_tile_batch@PAGEOFF
Lloh2:
	adrp	x11, _encoded_tile1@PAGE
Lloh3:
	add	x11, x11, _encoded_tile1@PAGEOFF
	cmp	x1, #1
	csel	x8, x11, x8, eq
	stp	x10, x9, [sp]
	blr	x8
	mov	w8, #0                          ; =0x0
	b	LBB0_19
	.loh AdrpAdd	Lloh2, Lloh3
	.loh AdrpAdd	Lloh0, Lloh1
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function encoded_tile1
_encoded_tile1:                         ; @encoded_tile1
	.cfi_startproc
; %bb.0:
	sub	sp, sp, #176
	stp	x28, x27, [sp, #80]             ; 16-byte Folded Spill
	stp	x26, x25, [sp, #96]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #112]            ; 16-byte Folded Spill
	stp	x22, x21, [sp, #128]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #144]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #160]            ; 16-byte Folded Spill
	.cfi_def_cfa_offset 176
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	.cfi_offset w25, -72
	.cfi_offset w26, -80
	.cfi_offset w27, -88
	.cfi_offset w28, -96
	str	x6, [sp, #32]                   ; 8-byte Folded Spill
	cmp	x2, #1
	b.lt	LBB1_88
; %bb.1:
	cmp	x1, #1
	b.lt	LBB1_88
; %bb.2:
	mov	x11, #0                         ; =0x0
	lsl	x9, x7, #2
	lsl	x10, x5, #1
	add	x8, x10, x5
	lsl	x8, x8, #1
	lsl	x13, x5, #3
	ldp	x12, x14, [sp, #176]
	str	x14, [sp, #48]                  ; 8-byte Folded Spill
	stp	x12, x13, [sp, #8]              ; 16-byte Folded Spill
	lsl	x15, x5, #2
	stp	x8, x9, [sp, #64]               ; 16-byte Folded Spill
	add	x16, x4, x8
	add	x17, x4, x15
	add	x5, x4, x10
	mov	w7, #32640                      ; =0x7f80
	mov	w21, #939524096                 ; =0x38000000
	movi.4h	v0, #124, lsl #8
	movi.4h	v1, #2, lsl #8
	movi.4s	v2, #64, lsl #16
	movi.4s	v3, #56, lsl #24
	movi.4s	v4, #128, lsl #24
                                        ; implicit-def: $q5
                                        ; implicit-def: $q6
                                        ; implicit-def: $q7
	mov	x25, x2
	str	x2, [sp, #24]                   ; 8-byte Folded Spill
	b	LBB1_4
LBB1_3:                                 ;   in Loop: Header=BB1_4 Depth=1
	ldr	x11, [sp, #40]                  ; 8-byte Folded Reload
	add	x11, x11, #4
	sub	x25, x25, #4
	ldp	x8, x2, [sp, #16]               ; 16-byte Folded Reload
	add	x4, x4, x8
	add	x16, x16, x8
	add	x17, x17, x8
	add	x5, x5, x8
	cmp	x11, x2
	b.ge	LBB1_88
LBB1_4:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB1_6 Depth 2
                                        ;       Child Loop BB1_54 Depth 3
                                        ;       Child Loop BB1_18 Depth 3
                                        ;       Child Loop BB1_26 Depth 3
                                        ;       Child Loop BB1_78 Depth 3
	mov	x26, #0                         ; =0x0
	sub	x27, x2, x11
	ldr	x2, [sp, #32]                   ; 8-byte Folded Reload
	str	x11, [sp, #40]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #8]                    ; 8-byte Folded Reload
	add	x8, x8, x11, lsl #2
	str	x8, [sp, #56]                   ; 8-byte Folded Spill
	b	LBB1_6
LBB1_5:                                 ;   in Loop: Header=BB1_6 Depth=2
	add	x26, x26, #1
	ldr	x8, [sp, #72]                   ; 8-byte Folded Reload
	add	x2, x2, x8
	cmp	x26, x1
	b.eq	LBB1_3
LBB1_6:                                 ;   Parent Loop BB1_4 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB1_54 Depth 3
                                        ;       Child Loop BB1_18 Depth 3
                                        ;       Child Loop BB1_26 Depth 3
                                        ;       Child Loop BB1_78 Depth 3
	sub	x14, x1, x26
	cmp	x3, #4
	b.ge	LBB1_13
; %bb.7:                                ;   in Loop: Header=BB1_6 Depth=2
	mov	x22, #0                         ; =0x0
	movi.2d	v16, #0000000000000000
	movi.2d	v17, #0000000000000000
	movi.2d	v18, #0000000000000000
	movi.2d	v19, #0000000000000000
LBB1_8:                                 ;   in Loop: Header=BB1_6 Depth=2
	movi	d22, #0000000000000000
	movi	d23, #0000000000000000
	movi	d21, #0000000000000000
	movi	d20, #0000000000000000
	subs	x12, x3, x22
	b.le	LBB1_82
; %bb.9:                                ;   in Loop: Header=BB1_6 Depth=2
	cmp	x27, #1
	b.lt	LBB1_5
; %bb.10:                               ;   in Loop: Header=BB1_6 Depth=2
	cmp	x14, #1
	cbz	w0, LBB1_75
; %bb.11:                               ;   in Loop: Header=BB1_6 Depth=2
	b.lt	LBB1_5
; %bb.12:                               ;   in Loop: Header=BB1_6 Depth=2
	mov	x6, #0                          ; =0x0
	add	x28, x2, x22, lsl #2
	lsl	x8, x22, #1
	add	x22, x16, x8
	add	x23, x17, x8
	add	x24, x5, x8
	add	x8, x4, x8
	b	LBB1_26
LBB1_13:                                ;   in Loop: Header=BB1_6 Depth=2
	mov	w8, #260046848                  ; =0xf800000
	dup.4s	v20, w8
	mov	w8, #947912704                  ; =0x38800000
	dup.4s	v21, w8
	mov	w8, #-1199570944                ; =0xb8800000
	dup.4s	v22, w8
	dup.4s	v23, w7
	cmp	x14, #1
	b.lt	LBB1_52
; %bb.14:                               ;   in Loop: Header=BB1_6 Depth=2
	cmp	x27, #3
	b.le	LBB1_52
; %bb.15:                               ;   in Loop: Header=BB1_6 Depth=2
	mov	x8, #0                          ; =0x0
	mov	x22, #0                         ; =0x0
	movi.2d	v16, #0000000000000000
	mov	x12, x2
	movi.2d	v17, #0000000000000000
	movi.2d	v18, #0000000000000000
	movi.2d	v19, #0000000000000000
	b	LBB1_18
LBB1_16:                                ;   in Loop: Header=BB1_18 Depth=3
	fmov	d25, d24
	bic.4h	v25, #128, lsl #8
	cmhi.4h	v25, v25, v0
	and.8b	v25, v25, v1
	orr.8b	v24, v25, v24
	fcvtl	v24.4s, v24.4h
	ldr	d25, [x5, x8]
	fmov	d26, d25
	bic.4h	v26, #128, lsl #8
	cmhi.4h	v26, v26, v0
	and.8b	v26, v26, v1
	orr.8b	v25, v26, v25
	fcvtl	v25.4s, v25.4h
	ldr	d26, [x17, x8]
	fmov	d27, d26
	bic.4h	v27, #128, lsl #8
	cmhi.4h	v27, v27, v0
	and.8b	v27, v27, v1
	orr.8b	v26, v27, v26
	fcvtl	v26.4s, v26.4h
	ldr	d27, [x16, x8]
	fmov	d28, d27
	bic.4h	v28, #128, lsl #8
	cmhi.4h	v28, v28, v0
	and.8b	v28, v28, v1
	orr.8b	v27, v28, v27
	fcvtl	v27.4s, v27.4h
LBB1_17:                                ;   in Loop: Header=BB1_18 Depth=3
	ldr	q28, [x12], #16
	fmla.4s	v19, v24, v28
	fmla.4s	v18, v25, v28
	fmla.4s	v17, v26, v28
	fmla.4s	v16, v27, v28
	add	x22, x13, #4
	add	x8, x8, #8
	add	x11, x13, #8
	cmp	x11, x3
	b.gt	LBB1_8
LBB1_18:                                ;   Parent Loop BB1_4 Depth=1
                                        ;     Parent Loop BB1_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	mov	x13, x22
	ldr	d24, [x4, x8]
	cmp	w0, #2
	b.eq	LBB1_16
; %bb.19:                               ;   in Loop: Header=BB1_18 Depth=3
	cbnz	w0, LBB1_21
; %bb.20:                               ;   in Loop: Header=BB1_18 Depth=3
	ushll.4s	v25, v24, #0
	shll.4s	v24, v24, #16
	bic.4s	v25, #128, lsl #8
	cmhi.4s	v25, v25, v23
	and.16b	v25, v25, v2
	orr.16b	v24, v25, v24
	ldr	d25, [x5, x8]
	ushll.4s	v26, v25, #0
	shll.4s	v25, v25, #16
	bic.4s	v26, #128, lsl #8
	cmhi.4s	v26, v26, v23
	and.16b	v26, v26, v2
	orr.16b	v25, v26, v25
	ldr	d26, [x17, x8]
	ushll.4s	v27, v26, #0
	shll.4s	v26, v26, #16
	bic.4s	v27, #128, lsl #8
	cmhi.4s	v27, v27, v23
	and.16b	v27, v27, v2
	orr.16b	v26, v27, v26
	ldr	d27, [x16, x8]
	ushll.4s	v28, v27, #0
	shll.4s	v27, v27, #16
	bic.4s	v28, #128, lsl #8
	cmhi.4s	v28, v28, v23
	and.16b	v28, v28, v2
	b	LBB1_22
LBB1_21:                                ;   in Loop: Header=BB1_18 Depth=3
	ushll.4s	v25, v24, #13
	and.16b	v26, v25, v20
	bic.4s	v25, #16, lsl #24
	cmeq.4s	v27, v26, v20
	cmeq.4s	v26, v26, #0
	and.16b	v27, v27, v3
	add.4s	v28, v25, v3
	add.4s	v27, v28, v27
	cmhi.4s	v28, v25, v20
	and.16b	v28, v28, v2
	orr.16b	v27, v27, v28
	add.4s	v25, v25, v21
	bif.16b	v25, v21, v26
	fadd.4s	v25, v25, v22
	fabs.4s	v25, v25
	bif.16b	v25, v27, v26
	sshll.4s	v24, v24, #0
	and.16b	v24, v24, v4
	orr.16b	v24, v25, v24
	ldr	d25, [x5, x8]
	ushll.4s	v26, v25, #13
	and.16b	v27, v26, v20
	bic.4s	v26, #16, lsl #24
	cmeq.4s	v28, v27, v20
	cmeq.4s	v27, v27, #0
	and.16b	v28, v28, v3
	add.4s	v29, v26, v3
	add.4s	v28, v29, v28
	cmhi.4s	v29, v26, v20
	and.16b	v29, v29, v2
	orr.16b	v28, v28, v29
	add.4s	v26, v26, v21
	bif.16b	v26, v21, v27
	fadd.4s	v26, v26, v22
	fabs.4s	v26, v26
	bif.16b	v26, v28, v27
	sshll.4s	v25, v25, #0
	and.16b	v25, v25, v4
	orr.16b	v25, v26, v25
	ldr	d26, [x17, x8]
	ushll.4s	v27, v26, #13
	and.16b	v28, v27, v20
	bic.4s	v27, #16, lsl #24
	cmeq.4s	v29, v28, v20
	cmeq.4s	v28, v28, #0
	and.16b	v29, v29, v3
	add.4s	v30, v27, v3
	add.4s	v29, v30, v29
	cmhi.4s	v30, v27, v20
	and.16b	v30, v30, v2
	orr.16b	v29, v29, v30
	add.4s	v27, v27, v21
	bif.16b	v27, v21, v28
	fadd.4s	v27, v27, v22
	fabs.4s	v27, v27
	bif.16b	v27, v29, v28
	sshll.4s	v26, v26, #0
	and.16b	v26, v26, v4
	orr.16b	v26, v27, v26
	ldr	d27, [x16, x8]
	ushll.4s	v28, v27, #13
	and.16b	v29, v28, v20
	bic.4s	v28, #16, lsl #24
	cmeq.4s	v30, v29, v20
	cmeq.4s	v29, v29, #0
	and.16b	v30, v30, v3
	add.4s	v31, v28, v3
	add.4s	v30, v31, v30
	cmhi.4s	v31, v28, v20
	and.16b	v31, v31, v2
	orr.16b	v30, v30, v31
	add.4s	v28, v28, v21
	bif.16b	v28, v21, v29
	fadd.4s	v28, v28, v22
	fabs.4s	v28, v28
	bif.16b	v28, v30, v29
	sshll.4s	v27, v27, #0
	and.16b	v27, v27, v4
LBB1_22:                                ;   in Loop: Header=BB1_18 Depth=3
	orr.16b	v27, v28, v27
	b	LBB1_17
LBB1_23:                                ;   in Loop: Header=BB1_26 Depth=3
	lsl	w11, w11, #13
	orr	w11, w11, w19, lsl #23
	add	w11, w11, w21
	orr	w30, w11, w30
LBB1_24:                                ;   in Loop: Header=BB1_26 Depth=3
	fmov	s25, w30
	fmul	s25, s24, s25
	fadd	s20, s20, s25
LBB1_25:                                ;   in Loop: Header=BB1_26 Depth=3
	fmov	s25, w13
	fmul	s24, s24, s25
	fadd	s22, s22, s24
	add	x6, x6, #1
	cmp	x12, x6
	b.eq	LBB1_82
LBB1_26:                                ;   Parent Loop BB1_4 Depth=1
                                        ;     Parent Loop BB1_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldrsh	w11, [x8, x6, lsl #1]
	and	w19, w11, #0xffff
	and	w13, w11, #0x80000000
	and	w30, w11, #0x3ff
	ubfx	w11, w11, #10, #5
	cmp	w11, #31
	b.eq	LBB1_32
; %bb.27:                               ;   in Loop: Header=BB1_26 Depth=3
	cbnz	w11, LBB1_30
; %bb.28:                               ;   in Loop: Header=BB1_26 Depth=3
	cbz	w30, LBB1_31
; %bb.29:                               ;   in Loop: Header=BB1_26 Depth=3
	clz	w11, w30
	eor	w20, w11, #0x1f
	mov	w9, #10                         ; =0xa
	sub	w20, w9, w20
	lsl	w19, w19, w20
	mov	w9, #22                         ; =0x16
	sub	w11, w9, w11
	and	w30, w19, #0x3fe
LBB1_30:                                ;   in Loop: Header=BB1_26 Depth=3
	lsl	w19, w30, #13
	orr	w11, w19, w11, lsl #23
	add	w11, w11, w21
	orr	w13, w11, w13
LBB1_31:                                ;   in Loop: Header=BB1_26 Depth=3
	ldr	s24, [x28, x6, lsl #2]
	cmp	x25, #2
	b.lt	LBB1_25
	b	LBB1_33
LBB1_32:                                ;   in Loop: Header=BB1_26 Depth=3
	lsl	w11, w19, #13
	cmp	w30, #0
	cset	w19, ne
	orr	w11, w11, w19, lsl #22
	orr	w11, w11, w13
	orr	w13, w11, #0x7f800000
	ldr	s24, [x28, x6, lsl #2]
	cmp	x25, #2
	b.lt	LBB1_25
LBB1_33:                                ;   in Loop: Header=BB1_26 Depth=3
	ldrsh	w19, [x24, x6, lsl #1]
	and	w20, w19, #0xffff
	and	w30, w19, #0x80000000
	and	w11, w19, #0x3ff
	ubfx	w19, w19, #10, #5
	cmp	w19, #31
	b.eq	LBB1_39
; %bb.34:                               ;   in Loop: Header=BB1_26 Depth=3
	cbnz	w19, LBB1_37
; %bb.35:                               ;   in Loop: Header=BB1_26 Depth=3
	cbz	w11, LBB1_38
; %bb.36:                               ;   in Loop: Header=BB1_26 Depth=3
	clz	w11, w11
	eor	w19, w11, #0x1f
	mov	w9, #10                         ; =0xa
	sub	w19, w9, w19
	lsl	w20, w20, w19
	mov	w9, #22                         ; =0x16
	sub	w19, w9, w11
	and	w11, w20, #0x3fe
LBB1_37:                                ;   in Loop: Header=BB1_26 Depth=3
	lsl	w11, w11, #13
	orr	w11, w11, w19, lsl #23
	add	w11, w11, w21
	orr	w30, w11, w30
LBB1_38:                                ;   in Loop: Header=BB1_26 Depth=3
	fmov	s25, w30
	fmul	s25, s24, s25
	fadd	s23, s23, s25
	cmp	x25, #2
	b.eq	LBB1_25
	b	LBB1_40
LBB1_39:                                ;   in Loop: Header=BB1_26 Depth=3
	lsl	w19, w20, #13
	cmp	w11, #0
	cset	w11, ne
	orr	w11, w19, w11, lsl #22
	orr	w11, w11, w30
	orr	w30, w11, #0x7f800000
	fmov	s25, w30
	fmul	s25, s24, s25
	fadd	s23, s23, s25
	cmp	x25, #2
	b.eq	LBB1_25
LBB1_40:                                ;   in Loop: Header=BB1_26 Depth=3
	ldrsh	w19, [x23, x6, lsl #1]
	and	w20, w19, #0xffff
	and	w30, w19, #0x80000000
	and	w11, w19, #0x3ff
	ubfx	w19, w19, #10, #5
	cmp	w19, #31
	b.eq	LBB1_46
; %bb.41:                               ;   in Loop: Header=BB1_26 Depth=3
	cbnz	w19, LBB1_44
; %bb.42:                               ;   in Loop: Header=BB1_26 Depth=3
	cbz	w11, LBB1_45
; %bb.43:                               ;   in Loop: Header=BB1_26 Depth=3
	clz	w11, w11
	eor	w19, w11, #0x1f
	mov	w9, #10                         ; =0xa
	sub	w19, w9, w19
	lsl	w20, w20, w19
	mov	w9, #22                         ; =0x16
	sub	w19, w9, w11
	and	w11, w20, #0x3fe
LBB1_44:                                ;   in Loop: Header=BB1_26 Depth=3
	lsl	w11, w11, #13
	orr	w11, w11, w19, lsl #23
	add	w11, w11, w21
	orr	w30, w11, w30
LBB1_45:                                ;   in Loop: Header=BB1_26 Depth=3
	fmov	s25, w30
	fmul	s25, s24, s25
	fadd	s21, s21, s25
	cmp	x25, #3
	b.eq	LBB1_25
	b	LBB1_47
LBB1_46:                                ;   in Loop: Header=BB1_26 Depth=3
	lsl	w19, w20, #13
	cmp	w11, #0
	cset	w11, ne
	orr	w11, w19, w11, lsl #22
	orr	w11, w11, w30
	orr	w30, w11, #0x7f800000
	fmov	s25, w30
	fmul	s25, s24, s25
	fadd	s21, s21, s25
	cmp	x25, #3
	b.eq	LBB1_25
LBB1_47:                                ;   in Loop: Header=BB1_26 Depth=3
	ldrsh	w19, [x22, x6, lsl #1]
	and	w20, w19, #0xffff
	and	w30, w19, #0x80000000
	and	w11, w19, #0x3ff
	ubfx	w19, w19, #10, #5
	cmp	w19, #31
	b.eq	LBB1_51
; %bb.48:                               ;   in Loop: Header=BB1_26 Depth=3
	cbnz	w19, LBB1_23
; %bb.49:                               ;   in Loop: Header=BB1_26 Depth=3
	cbz	w11, LBB1_24
; %bb.50:                               ;   in Loop: Header=BB1_26 Depth=3
	clz	w11, w11
	eor	w19, w11, #0x1f
	mov	w9, #10                         ; =0xa
	sub	w19, w9, w19
	lsl	w20, w20, w19
	mov	w9, #22                         ; =0x16
	sub	w19, w9, w11
	and	w11, w20, #0x3fe
	b	LBB1_23
LBB1_51:                                ;   in Loop: Header=BB1_26 Depth=3
	lsl	w19, w20, #13
	cmp	w11, #0
	cset	w11, ne
	orr	w11, w19, w11, lsl #22
	orr	w11, w11, w30
	orr	w30, w11, #0x7f800000
	b	LBB1_24
LBB1_52:                                ;   in Loop: Header=BB1_6 Depth=2
	mov	x6, #0                          ; =0x0
	movi.2d	v16, #0000000000000000
	mov	x12, x4
	mov	x28, x2
	movi.2d	v17, #0000000000000000
	movi.2d	v18, #0000000000000000
	movi.2d	v19, #0000000000000000
	b	LBB1_54
LBB1_53:                                ;   in Loop: Header=BB1_54 Depth=3
	add	x22, x6, #4
	add	x28, x28, #16
	add	x12, x12, #8
	add	x8, x6, #8
	mov	x6, x22
	cmp	x8, x3
	b.gt	LBB1_8
LBB1_54:                                ;   Parent Loop BB1_4 Depth=1
                                        ;     Parent Loop BB1_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	cmp	x27, #1
	b.lt	LBB1_53
; %bb.55:                               ;   in Loop: Header=BB1_54 Depth=3
	cbz	w0, LBB1_61
; %bb.56:                               ;   in Loop: Header=BB1_54 Depth=3
	cmp	w0, #2
	b.ne	LBB1_65
; %bb.57:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	d24, [x12]
	fmov	d25, d24
	bic.4h	v25, #128, lsl #8
	cmhi.4h	v25, v25, v0
	and.8b	v25, v25, v1
	orr.8b	v24, v25, v24
	fcvtl	v24.4s, v24.4h
	cmp	x25, #2
	b.lt	LBB1_70
; %bb.58:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	d7, [x12, x10]
	fmov	d25, d7
	bic.4h	v25, #128, lsl #8
	cmhi.4h	v25, v25, v0
	and.8b	v25, v25, v1
	orr.8b	v7, v25, v7
	fcvtl	v7.4s, v7.4h
	cmp	x25, #2
	b.eq	LBB1_70
; %bb.59:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	d6, [x12, x15]
	fmov	d25, d6
	bic.4h	v25, #128, lsl #8
	cmhi.4h	v25, v25, v0
	and.8b	v25, v25, v1
	orr.8b	v6, v25, v6
	fcvtl	v6.4s, v6.4h
	cmp	x25, #3
	b.eq	LBB1_70
; %bb.60:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	x8, [sp, #64]                   ; 8-byte Folded Reload
	ldr	d5, [x12, x8]
	fmov	d25, d5
	bic.4h	v25, #128, lsl #8
	cmhi.4h	v25, v25, v0
	and.8b	v25, v25, v1
	orr.8b	v5, v25, v5
	fcvtl	v5.4s, v5.4h
	b	LBB1_70
LBB1_61:                                ;   in Loop: Header=BB1_54 Depth=3
	ldr	d24, [x12]
	ushll.4s	v25, v24, #0
	shll.4s	v24, v24, #16
	bic.4s	v25, #128, lsl #8
	cmhi.4s	v25, v25, v23
	and.16b	v25, v25, v2
	orr.16b	v24, v25, v24
	cmp	x25, #1
	b.le	LBB1_70
; %bb.62:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	d7, [x12, x10]
	ushll.4s	v25, v7, #0
	shll.4s	v7, v7, #16
	bic.4s	v25, #128, lsl #8
	cmhi.4s	v25, v25, v23
	and.16b	v25, v25, v2
	orr.16b	v7, v25, v7
	cmp	x25, #2
	b.eq	LBB1_70
; %bb.63:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	d6, [x12, x15]
	ushll.4s	v25, v6, #0
	shll.4s	v6, v6, #16
	bic.4s	v25, #128, lsl #8
	cmhi.4s	v25, v25, v23
	and.16b	v25, v25, v2
	orr.16b	v6, v25, v6
	cmp	x25, #3
	b.eq	LBB1_70
; %bb.64:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	x8, [sp, #64]                   ; 8-byte Folded Reload
	ldr	d5, [x12, x8]
	ushll.4s	v25, v5, #0
	shll.4s	v5, v5, #16
	bic.4s	v25, #128, lsl #8
	cmhi.4s	v25, v25, v23
	and.16b	v25, v25, v2
	b	LBB1_69
LBB1_65:                                ;   in Loop: Header=BB1_54 Depth=3
	ldr	d24, [x12]
	ushll.4s	v25, v24, #13
	and.16b	v26, v25, v20
	bic.4s	v25, #16, lsl #24
	cmeq.4s	v27, v26, v20
	cmeq.4s	v26, v26, #0
	and.16b	v27, v27, v3
	add.4s	v28, v25, v3
	add.4s	v27, v28, v27
	cmhi.4s	v28, v25, v20
	and.16b	v28, v28, v2
	orr.16b	v27, v27, v28
	add.4s	v25, v25, v21
	bif.16b	v25, v21, v26
	fadd.4s	v25, v25, v22
	fabs.4s	v25, v25
	bif.16b	v25, v27, v26
	sshll.4s	v24, v24, #0
	and.16b	v24, v24, v4
	orr.16b	v24, v25, v24
	cmp	x25, #2
	b.lt	LBB1_70
; %bb.66:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	d7, [x12, x10]
	ushll.4s	v25, v7, #13
	and.16b	v26, v25, v20
	bic.4s	v25, #16, lsl #24
	cmeq.4s	v27, v26, v20
	cmeq.4s	v26, v26, #0
	and.16b	v27, v27, v3
	add.4s	v28, v25, v3
	add.4s	v27, v28, v27
	cmhi.4s	v28, v25, v20
	and.16b	v28, v28, v2
	orr.16b	v27, v27, v28
	add.4s	v25, v25, v21
	bif.16b	v25, v21, v26
	fadd.4s	v25, v25, v22
	fabs.4s	v25, v25
	bif.16b	v25, v27, v26
	sshll.4s	v7, v7, #0
	and.16b	v7, v7, v4
	orr.16b	v7, v25, v7
	cmp	x25, #2
	b.eq	LBB1_70
; %bb.67:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	d6, [x12, x15]
	ushll.4s	v25, v6, #13
	and.16b	v26, v25, v20
	bic.4s	v25, #16, lsl #24
	cmeq.4s	v27, v26, v20
	cmeq.4s	v26, v26, #0
	and.16b	v27, v27, v3
	add.4s	v28, v25, v3
	add.4s	v27, v28, v27
	cmhi.4s	v28, v25, v20
	and.16b	v28, v28, v2
	orr.16b	v27, v27, v28
	add.4s	v25, v25, v21
	bif.16b	v25, v21, v26
	fadd.4s	v25, v25, v22
	fabs.4s	v25, v25
	bif.16b	v25, v27, v26
	sshll.4s	v6, v6, #0
	and.16b	v6, v6, v4
	orr.16b	v6, v25, v6
	cmp	x25, #3
	b.eq	LBB1_70
; %bb.68:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	x8, [sp, #64]                   ; 8-byte Folded Reload
	ldr	d5, [x12, x8]
	ushll.4s	v25, v5, #13
	and.16b	v26, v25, v20
	bic.4s	v25, #16, lsl #24
	cmeq.4s	v27, v26, v20
	cmeq.4s	v26, v26, #0
	and.16b	v27, v27, v3
	add.4s	v28, v25, v3
	add.4s	v27, v28, v27
	cmhi.4s	v28, v25, v20
	and.16b	v28, v28, v2
	orr.16b	v27, v27, v28
	add.4s	v25, v25, v21
	bif.16b	v25, v21, v26
	fadd.4s	v25, v25, v22
	fabs.4s	v25, v25
	bif.16b	v25, v27, v26
	sshll.4s	v5, v5, #0
	and.16b	v5, v5, v4
LBB1_69:                                ;   in Loop: Header=BB1_54 Depth=3
	orr.16b	v5, v25, v5
LBB1_70:                                ;   in Loop: Header=BB1_54 Depth=3
	cmp	x14, #1
	b.lt	LBB1_53
; %bb.71:                               ;   in Loop: Header=BB1_54 Depth=3
	ldr	q25, [x28]
	fmla.4s	v19, v24, v25
	cmp	x25, #2
	b.lt	LBB1_53
; %bb.72:                               ;   in Loop: Header=BB1_54 Depth=3
	fmla.4s	v18, v7, v25
	b.eq	LBB1_53
; %bb.73:                               ;   in Loop: Header=BB1_54 Depth=3
	fmla.4s	v17, v6, v25
	cmp	x25, #3
	b.eq	LBB1_53
; %bb.74:                               ;   in Loop: Header=BB1_54 Depth=3
	fmla.4s	v16, v5, v25
	b	LBB1_53
LBB1_75:                                ;   in Loop: Header=BB1_6 Depth=2
	b.lt	LBB1_5
; %bb.76:                               ;   in Loop: Header=BB1_6 Depth=2
	mov	x8, #0                          ; =0x0
	add	x13, x2, x22, lsl #2
	lsl	x11, x22, #1
	add	x6, x16, x11
	add	x22, x17, x11
	add	x23, x5, x11
	add	x24, x4, x11
	b	LBB1_78
LBB1_77:                                ;   in Loop: Header=BB1_78 Depth=3
	fmov	s25, w28
	fmul	s24, s24, s25
	fadd	s22, s22, s24
	add	x8, x8, #1
	cmp	x12, x8
	b.eq	LBB1_82
LBB1_78:                                ;   Parent Loop BB1_4 Depth=1
                                        ;     Parent Loop BB1_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldr	s24, [x13, x8, lsl #2]
	ldrh	w11, [x24, x8, lsl #1]
	lsl	w19, w11, #16
	and	w11, w11, #0x7fff
	orr	w20, w19, #0x400000
	cmp	w11, w7
	csel	w28, w20, w19, hi
	cmp	x25, #2
	b.lt	LBB1_77
; %bb.79:                               ;   in Loop: Header=BB1_78 Depth=3
	ldrh	w11, [x23, x8, lsl #1]
	lsl	w19, w11, #16
	and	w11, w11, #0x7fff
	orr	w20, w19, #0x400000
	cmp	w11, w7
	csel	w11, w20, w19, hi
	fmov	s25, w11
	fmul	s25, s24, s25
	fadd	s23, s23, s25
	cmp	x25, #2
	b.eq	LBB1_77
; %bb.80:                               ;   in Loop: Header=BB1_78 Depth=3
	ldrh	w11, [x22, x8, lsl #1]
	lsl	w19, w11, #16
	and	w11, w11, #0x7fff
	orr	w20, w19, #0x400000
	cmp	w11, w7
	csel	w11, w20, w19, hi
	fmov	s25, w11
	fmul	s25, s24, s25
	fadd	s21, s21, s25
	cmp	x25, #3
	b.eq	LBB1_77
; %bb.81:                               ;   in Loop: Header=BB1_78 Depth=3
	ldrh	w11, [x6, x8, lsl #1]
	lsl	w19, w11, #16
	and	w11, w11, #0x7fff
	orr	w20, w19, #0x400000
	cmp	w11, w7
	csel	w11, w20, w19, hi
	fmov	s25, w11
	fmul	s25, s24, s25
	fadd	s20, s20, s25
	b	LBB1_77
LBB1_82:                                ;   in Loop: Header=BB1_6 Depth=2
	cmp	x14, #1
	b.lt	LBB1_5
; %bb.83:                               ;   in Loop: Header=BB1_6 Depth=2
	cmp	x27, #1
	b.lt	LBB1_5
; %bb.84:                               ;   in Loop: Header=BB1_6 Depth=2
	ldp	x8, x9, [sp, #48]               ; 16-byte Folded Reload
	mul	x8, x26, x8
	add	x8, x9, x8, lsl #2
	faddp.4s	v19, v19, v19
	faddp.2s	s19, v19
	fadd	s19, s19, s22
	str	s19, [x8]
	cmp	x25, #2
	b.lt	LBB1_5
; %bb.85:                               ;   in Loop: Header=BB1_6 Depth=2
	faddp.4s	v18, v18, v18
	faddp.2s	s18, v18
	fadd	s18, s18, s23
	str	s18, [x8, #4]
	cmp	x25, #2
	b.eq	LBB1_5
; %bb.86:                               ;   in Loop: Header=BB1_6 Depth=2
	faddp.4s	v17, v17, v17
	faddp.2s	s17, v17
	fadd	s17, s17, s21
	str	s17, [x8, #8]
	cmp	x25, #3
	b.eq	LBB1_5
; %bb.87:                               ;   in Loop: Header=BB1_6 Depth=2
	faddp.4s	v16, v16, v16
	faddp.2s	s16, v16
	fadd	s16, s16, s20
	str	s16, [x8, #12]
	b	LBB1_5
LBB1_88:
	ldp	x29, x30, [sp, #160]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #144]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #128]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #112]            ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #96]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #80]             ; 16-byte Folded Reload
	add	sp, sp, #176
	ret
	.cfi_endproc
                                        ; -- End function
	.p2align	2                               ; -- Begin function encoded_tile_batch
_encoded_tile_batch:                    ; @encoded_tile_batch
	.cfi_startproc
; %bb.0:
	stp	d15, d14, [sp, #-160]!          ; 16-byte Folded Spill
	stp	d13, d12, [sp, #16]             ; 16-byte Folded Spill
	stp	d11, d10, [sp, #32]             ; 16-byte Folded Spill
	stp	d9, d8, [sp, #48]               ; 16-byte Folded Spill
	stp	x28, x27, [sp, #64]             ; 16-byte Folded Spill
	stp	x26, x25, [sp, #80]             ; 16-byte Folded Spill
	stp	x24, x23, [sp, #96]             ; 16-byte Folded Spill
	stp	x22, x21, [sp, #112]            ; 16-byte Folded Spill
	stp	x20, x19, [sp, #128]            ; 16-byte Folded Spill
	stp	x29, x30, [sp, #144]            ; 16-byte Folded Spill
	sub	sp, sp, #496
	.cfi_def_cfa_offset 656
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w21, -40
	.cfi_offset w22, -48
	.cfi_offset w23, -56
	.cfi_offset w24, -64
	.cfi_offset w25, -72
	.cfi_offset w26, -80
	.cfi_offset w27, -88
	.cfi_offset w28, -96
	.cfi_offset b8, -104
	.cfi_offset b9, -112
	.cfi_offset b10, -120
	.cfi_offset b11, -128
	.cfi_offset b12, -136
	.cfi_offset b13, -144
	.cfi_offset b14, -152
	.cfi_offset b15, -160
	str	x7, [sp, #104]                  ; 8-byte Folded Spill
	str	x6, [sp, #72]                   ; 8-byte Folded Spill
	cmp	x2, #1
	b.lt	LBB2_202
; %bb.1:
	cmp	x1, #1
	b.lt	LBB2_202
; %bb.2:
	mov	x11, x4
	mov	x14, #0                         ; =0x0
	ldr	x12, [sp, #104]                 ; 8-byte Folded Reload
	add	x8, x12, x12, lsl #1
	lsl	x9, x12, #2
	add	x10, x9, x12
	lsl	x4, x10, #2
	lsl	x6, x8, #2
	lsl	x13, x5, #1
	add	x10, x13, x5
	lsl	x10, x10, #1
	lsl	x16, x5, #2
	str	x10, [sp, #160]                 ; 8-byte Folded Spill
	add	x15, x11, x10
	str	x16, [sp, #256]                 ; 8-byte Folded Spill
	add	x16, x11, x16
	stp	x6, x13, [sp, #128]             ; 16-byte Folded Spill
	add	x17, x11, x13
	ldr	x13, [sp, #72]                  ; 8-byte Folded Reload
	str	x4, [sp, #88]                   ; 8-byte Folded Spill
	add	x10, x13, x4
	stp	x10, x2, [sp, #56]              ; 16-byte Folded Spill
	add	x10, x13, x6
	str	x10, [sp, #48]                  ; 8-byte Folded Spill
	lsl	x10, x12, #3
	str	x10, [sp, #184]                 ; 8-byte Folded Spill
	add	x10, x13, x10
	lsl	x8, x8, #3
	stp	x8, x1, [sp, #192]              ; 16-byte Folded Spill
	ldr	x8, [sp, #664]
	str	x8, [sp, #168]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #656]
	stp	x8, x10, [sp, #32]              ; 16-byte Folded Spill
	add	x8, x13, x9
	str	x8, [sp, #24]                   ; 8-byte Folded Spill
	lsl	x8, x5, #3
	str	x8, [sp, #16]                   ; 8-byte Folded Spill
	movi.4h	v6, #124, lsl #8
                                        ; implicit-def: $q13
                                        ; implicit-def: $q15
                                        ; implicit-def: $q0
	mov	x10, x2
	add	x8, x13, x12, lsl #4
	str	x8, [sp, #8]                    ; 8-byte Folded Spill
	b	LBB2_4
LBB2_3:                                 ;   in Loop: Header=BB2_4 Depth=1
	ldr	x14, [sp, #80]                  ; 8-byte Folded Reload
	add	x14, x14, #4
	sub	x10, x10, #4
	ldr	x8, [sp, #16]                   ; 8-byte Folded Reload
	add	x11, x11, x8
	add	x15, x15, x8
	add	x16, x16, x8
	add	x17, x17, x8
	ldr	x2, [sp, #64]                   ; 8-byte Folded Reload
	cmp	x14, x2
	b.ge	LBB2_202
LBB2_4:                                 ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB2_6 Depth 2
                                        ;       Child Loop BB2_26 Depth 3
                                        ;       Child Loop BB2_18 Depth 3
                                        ;       Child Loop BB2_79 Depth 3
                                        ;       Child Loop BB2_138 Depth 3
	mov	x26, #0                         ; =0x0
	sub	x6, x2, x14
	ldr	x8, [sp, #24]                   ; 8-byte Folded Reload
	str	x8, [sp, #312]                  ; 8-byte Folded Spill
	ldp	x5, x19, [sp, #40]              ; 16-byte Folded Reload
	ldr	x7, [sp, #8]                    ; 8-byte Folded Reload
	ldr	x20, [sp, #56]                  ; 8-byte Folded Reload
	ldr	x28, [sp, #72]                  ; 8-byte Folded Reload
	mov	x2, x1
	str	x14, [sp, #80]                  ; 8-byte Folded Spill
	ldr	x8, [sp, #32]                   ; 8-byte Folded Reload
	add	x8, x8, x14, lsl #2
	str	x8, [sp, #176]                  ; 8-byte Folded Spill
	b	LBB2_6
LBB2_5:                                 ;   in Loop: Header=BB2_6 Depth=2
	add	x26, x26, #6
	sub	x2, x2, #6
	ldp	x8, x1, [sp, #192]              ; 16-byte Folded Reload
	add	x28, x28, x8
	add	x20, x20, x8
	add	x7, x7, x8
	add	x19, x19, x8
	add	x5, x5, x8
	ldr	x12, [sp, #312]                 ; 8-byte Folded Reload
	add	x12, x12, x8
	str	x12, [sp, #312]                 ; 8-byte Folded Spill
	cmp	x26, x1
	ldr	q15, [sp, #336]                 ; 16-byte Folded Reload
	ldr	q0, [sp, #368]                  ; 16-byte Folded Reload
	b.ge	LBB2_3
LBB2_6:                                 ;   Parent Loop BB2_4 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB2_26 Depth 3
                                        ;       Child Loop BB2_18 Depth 3
                                        ;       Child Loop BB2_79 Depth 3
                                        ;       Child Loop BB2_138 Depth 3
	sub	x13, x1, x26
	cmp	x3, #4
	b.ge	LBB2_13
; %bb.7:                                ;   in Loop: Header=BB2_6 Depth=2
	mov	x27, #0                         ; =0x0
	movi.2d	v7, #0000000000000000
	movi.2d	v21, #0000000000000000
	movi.2d	v23, #0000000000000000
	movi.2d	v28, #0000000000000000
	movi.2d	v16, #0000000000000000
	movi.2d	v22, #0000000000000000
	movi.2d	v24, #0000000000000000
	movi.2d	v25, #0000000000000000
	movi.2d	v26, #0000000000000000
	movi.2d	v27, #0000000000000000
	movi.2d	v19, #0000000000000000
	movi.2d	v29, #0000000000000000
	movi.2d	v31, #0000000000000000
	movi.2d	v30, #0000000000000000
	movi.2d	v9, #0000000000000000
	movi.2d	v20, #0000000000000000
	movi.2d	v8, #0000000000000000
	movi.2d	v11, #0000000000000000
	movi.2d	v12, #0000000000000000
	movi.2d	v18, #0000000000000000
	movi.2d	v10, #0000000000000000
	movi.2d	v1, #0000000000000000
	str	q1, [sp, #480]                  ; 16-byte Folded Spill
	movi.2d	v14, #0000000000000000
	mov	w1, #32640                      ; =0x7f80
LBB2_8:                                 ;   in Loop: Header=BB2_6 Depth=2
	stp	q11, q1, [sp, #416]             ; 32-byte Folded Spill
	str	q15, [sp, #336]                 ; 16-byte Folded Spill
	str	q0, [sp, #368]                  ; 16-byte Folded Spill
	str	q14, [sp, #448]                 ; 16-byte Folded Spill
	str	q21, [sp, #208]                 ; 16-byte Folded Spill
	movi	d0, #0000000000000000
	movi	d1, #0000000000000000
	str	s1, [sp, #464]                  ; 4-byte Folded Spill
	str	s1, [sp, #400]                  ; 4-byte Folded Spill
	str	s1, [sp, #352]                  ; 4-byte Folded Spill
	movi	d11, #0000000000000000
	movi	d14, #0000000000000000
	str	s1, [sp, #384]                  ; 4-byte Folded Spill
	str	s1, [sp, #304]                  ; 4-byte Folded Spill
	movi	d4, #0000000000000000
	movi	d15, #0000000000000000
	movi	d21, #0000000000000000
	str	s1, [sp, #288]                  ; 4-byte Folded Spill
	movi	d17, #0000000000000000
	movi	d2, #0000000000000000
	str	s2, [sp, #308]                  ; 4-byte Folded Spill
	str	s2, [sp, #292]                  ; 4-byte Folded Spill
	str	s2, [sp, #276]                  ; 4-byte Folded Spill
	str	s2, [sp, #320]                  ; 4-byte Folded Spill
	str	s2, [sp, #300]                  ; 4-byte Folded Spill
	str	s2, [sp, #284]                  ; 4-byte Folded Spill
	str	s2, [sp, #268]                  ; 4-byte Folded Spill
	str	s2, [sp, #296]                  ; 4-byte Folded Spill
	str	s2, [sp, #280]                  ; 4-byte Folded Spill
	str	s2, [sp, #272]                  ; 4-byte Folded Spill
	str	s2, [sp, #252]                  ; 4-byte Folded Spill
	subs	x24, x3, x27
	b.le	LBB2_171
; %bb.9:                                ;   in Loop: Header=BB2_6 Depth=2
	cmp	x6, #1
	b.lt	LBB2_5
; %bb.10:                               ;   in Loop: Header=BB2_6 Depth=2
	cmp	x13, #1
	cbz	w0, LBB2_75
; %bb.11:                               ;   in Loop: Header=BB2_6 Depth=2
	b.lt	LBB2_5
; %bb.12:                               ;   in Loop: Header=BB2_6 Depth=2
	mov	x4, #0                          ; =0x0
	str	s1, [sp, #464]                  ; 4-byte Folded Spill
	lsl	x8, x27, #2
	str	s1, [sp, #400]                  ; 4-byte Folded Spill
	add	x12, x20, x8
	str	x12, [sp, #112]                 ; 8-byte Folded Spill
	str	s1, [sp, #352]                  ; 4-byte Folded Spill
	add	x12, x7, x8
	str	x12, [sp, #144]                 ; 8-byte Folded Spill
	add	x12, x19, x8
	str	x12, [sp, #232]                 ; 8-byte Folded Spill
	add	x14, x5, x8
	str	s1, [sp, #384]                  ; 4-byte Folded Spill
	ldr	x12, [sp, #312]                 ; 8-byte Folded Reload
	add	x22, x12, x8
	str	s1, [sp, #304]                  ; 4-byte Folded Spill
	add	x25, x28, x8
	lsl	x8, x27, #1
	add	x12, x15, x8
	str	x12, [sp, #152]                 ; 8-byte Folded Spill
	add	x12, x16, x8
	str	x12, [sp, #240]                 ; 8-byte Folded Spill
	str	s1, [sp, #288]                  ; 4-byte Folded Spill
	add	x27, x17, x8
	add	x12, x11, x8
	str	s2, [sp, #308]                  ; 4-byte Folded Spill
	str	s2, [sp, #292]                  ; 4-byte Folded Spill
	str	s2, [sp, #276]                  ; 4-byte Folded Spill
	str	s2, [sp, #320]                  ; 4-byte Folded Spill
	str	s2, [sp, #300]                  ; 4-byte Folded Spill
	str	s2, [sp, #284]                  ; 4-byte Folded Spill
	str	s2, [sp, #268]                  ; 4-byte Folded Spill
	str	s2, [sp, #296]                  ; 4-byte Folded Spill
	str	s2, [sp, #280]                  ; 4-byte Folded Spill
	str	s2, [sp, #272]                  ; 4-byte Folded Spill
	str	s2, [sp, #252]                  ; 4-byte Folded Spill
	b	LBB2_79
LBB2_13:                                ;   in Loop: Header=BB2_6 Depth=2
	mov	w8, #260046848                  ; =0xf800000
	dup.4s	v2, w8
	mov	w8, #947912704                  ; =0x38800000
	dup.4s	v17, w8
	mov	w8, #-1199570944                ; =0xb8800000
	dup.4s	v1, w8
	stp	q1, q2, [sp, #336]              ; 32-byte Folded Spill
	mov	w1, #32640                      ; =0x7f80
	dup.4s	v5, w1
	cmp	x13, #6
	ldr	x12, [sp, #136]                 ; 8-byte Folded Reload
	str	q5, [sp, #464]                  ; 16-byte Folded Spill
	b.lt	LBB2_23
; %bb.14:                               ;   in Loop: Header=BB2_6 Depth=2
	cmp	x6, #3
	b.le	LBB2_23
; %bb.15:                               ;   in Loop: Header=BB2_6 Depth=2
	mov	x8, #0                          ; =0x0
	mov	x14, #0                         ; =0x0
	movi.2d	v7, #0000000000000000
	movi.2d	v21, #0000000000000000
	movi.2d	v23, #0000000000000000
	mov	x12, x28
	movi.2d	v28, #0000000000000000
	movi.2d	v16, #0000000000000000
	movi.2d	v22, #0000000000000000
	movi.2d	v24, #0000000000000000
	movi.2d	v25, #0000000000000000
	movi.2d	v20, #0000000000000000
	movi.2d	v8, #0000000000000000
	movi.2d	v11, #0000000000000000
	movi.2d	v12, #0000000000000000
	movi.2d	v18, #0000000000000000
	movi.2d	v10, #0000000000000000
	movi.2d	v0, #0000000000000000
	str	q0, [sp, #480]                  ; 16-byte Folded Spill
	movi.2d	v1, #0000000000000000
	movi.2d	v14, #0000000000000000
	movi.2d	v26, #0000000000000000
	movi.2d	v27, #0000000000000000
	movi.2d	v19, #0000000000000000
	movi.2d	v29, #0000000000000000
	movi.2d	v31, #0000000000000000
	movi.2d	v30, #0000000000000000
	movi.2d	v9, #0000000000000000
	b	LBB2_18
LBB2_16:                                ;   in Loop: Header=BB2_18 Depth=3
	fmov	d2, d3
	bic.4h	v2, #128, lsl #8
	cmhi.4h	v2, v2, v6
	movi.4h	v5, #2, lsl #8
	and.8b	v2, v2, v5
	orr.8b	v2, v2, v3
	fcvtl	v3.4s, v2.4h
	ldr	d2, [x17, x8]
	fmov	d4, d2
	bic.4h	v4, #128, lsl #8
	cmhi.4h	v4, v4, v6
	and.8b	v4, v4, v5
	orr.8b	v2, v4, v2
	fcvtl	v0.4s, v2.4h
	ldr	d2, [x16, x8]
	fmov	d4, d2
	bic.4h	v4, #128, lsl #8
	cmhi.4h	v4, v4, v6
	and.8b	v4, v4, v5
	orr.8b	v2, v4, v2
	fcvtl	v15.4s, v2.4h
	ldr	d2, [x15, x8]
	fmov	d4, d2
	bic.4h	v4, #128, lsl #8
	cmhi.4h	v4, v4, v6
	and.8b	v4, v4, v5
	orr.8b	v2, v4, v2
	fcvtl	v13.4s, v2.4h
LBB2_17:                                ;   in Loop: Header=BB2_18 Depth=3
	ldr	q2, [x12]
	fmla.4s	v14, v3, v2
	fmla.4s	v1, v0, v2
	ldr	q4, [sp, #480]                  ; 16-byte Folded Reload
	fmla.4s	v4, v15, v2
	str	q4, [sp, #480]                  ; 16-byte Folded Spill
	fmla.4s	v10, v13, v2
	add	x4, x12, x9
	add	x21, x4, x9
	ldr	q2, [x4]
	fmla.4s	v18, v3, v2
	fmla.4s	v12, v0, v2
	fmla.4s	v11, v15, v2
	fmla.4s	v8, v13, v2
	ldr	q2, [x21]
	fmla.4s	v20, v3, v2
	fmla.4s	v9, v0, v2
	fmla.4s	v30, v15, v2
	fmla.4s	v31, v13, v2
	add	x4, x21, x9
	add	x21, x4, x9
	ldr	q2, [x4]
	fmla.4s	v29, v3, v2
	fmla.4s	v19, v0, v2
	fmla.4s	v27, v15, v2
	fmla.4s	v26, v13, v2
	ldr	q2, [x21]
	fmla.4s	v25, v3, v2
	fmla.4s	v24, v0, v2
	fmla.4s	v22, v15, v2
	fmla.4s	v16, v13, v2
	ldr	q2, [x21, x9]
	fmla.4s	v28, v3, v2
	add	x27, x14, #4
	fmla.4s	v23, v0, v2
	add	x12, x12, #16
	add	x8, x8, #8
	fmla.4s	v21, v15, v2
	add	x4, x14, #8
	mov	x14, x27
	fmla.4s	v7, v13, v2
	cmp	x4, x3
	ldr	q5, [sp, #464]                  ; 16-byte Folded Reload
	b.gt	LBB2_8
LBB2_18:                                ;   Parent Loop BB2_4 Depth=1
                                        ;     Parent Loop BB2_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldr	d3, [x11, x8]
	cmp	w0, #2
	b.eq	LBB2_16
; %bb.19:                               ;   in Loop: Header=BB2_18 Depth=3
	cbnz	w0, LBB2_21
; %bb.20:                               ;   in Loop: Header=BB2_18 Depth=3
	ushll.4s	v2, v3, #0
	shll.4s	v3, v3, #16
	bic.4s	v2, #128, lsl #8
	cmhi.4s	v2, v2, v5
	mov.16b	v6, v5
	movi.4s	v5, #64, lsl #16
	and.16b	v2, v2, v5
	orr.16b	v3, v2, v3
	ldr	d2, [x17, x8]
	ushll.4s	v4, v2, #0
	shll.4s	v2, v2, #16
	bic.4s	v4, #128, lsl #8
	cmhi.4s	v4, v4, v6
	and.16b	v4, v4, v5
	orr.16b	v0, v4, v2
	ldr	d2, [x16, x8]
	ushll.4s	v4, v2, #0
	shll.4s	v2, v2, #16
	bic.4s	v4, #128, lsl #8
	cmhi.4s	v4, v4, v6
	and.16b	v4, v4, v5
	orr.16b	v15, v4, v2
	ldr	d2, [x15, x8]
	ushll.4s	v4, v2, #0
	shll.4s	v2, v2, #16
	bic.4s	v4, #128, lsl #8
	cmhi.4s	v4, v4, v6
	movi.4h	v6, #124, lsl #8
	and.16b	v4, v4, v5
	b	LBB2_22
LBB2_21:                                ;   in Loop: Header=BB2_18 Depth=3
	ushll.4s	v2, v3, #13
	ldr	q0, [sp, #352]                  ; 16-byte Folded Reload
	and.16b	v4, v2, v0
	bic.4s	v2, #16, lsl #24
	cmeq.4s	v5, v4, v0
	cmeq.4s	v4, v4, #0
	stp	q10, q11, [sp, #400]            ; 32-byte Folded Spill
	mov.16b	v11, v8
	mov.16b	v10, v20
	mov.16b	v8, v27
	mov.16b	v27, v25
	mov.16b	v25, v16
	mov.16b	v16, v23
	movi.4s	v23, #56, lsl #24
	and.16b	v5, v5, v23
	add.4s	v6, v2, v23
	add.4s	v5, v6, v5
	cmhi.4s	v6, v2, v0
	stp	q9, q12, [sp, #368]             ; 32-byte Folded Spill
	mov.16b	v12, v30
	mov.16b	v30, v31
	mov.16b	v31, v19
	mov.16b	v13, v24
	mov.16b	v24, v28
	mov.16b	v28, v7
	movi.4s	v19, #64, lsl #16
	and.16b	v6, v6, v19
	orr.16b	v5, v5, v6
	add.4s	v2, v2, v17
	bif.16b	v2, v17, v4
	ldr	q7, [sp, #336]                  ; 16-byte Folded Reload
	fadd.4s	v2, v2, v7
	fabs.4s	v2, v2
	bif.16b	v2, v5, v4
	sshll.4s	v3, v3, #0
	stp	q1, q14, [sp, #432]             ; 32-byte Folded Spill
	mov.16b	v14, v18
	mov.16b	v9, v29
	mov.16b	v29, v26
	mov.16b	v26, v22
	mov.16b	v22, v16
	movi.4s	v18, #128, lsl #24
	and.16b	v3, v3, v18
	orr.16b	v3, v2, v3
	ldr	d2, [x17, x8]
	ushll.4s	v4, v2, #13
	and.16b	v5, v4, v0
	bic.4s	v4, #16, lsl #24
	cmeq.4s	v6, v5, v0
	cmeq.4s	v5, v5, #0
	and.16b	v6, v6, v23
	add.4s	v16, v4, v23
	add.4s	v6, v16, v6
	cmhi.4s	v16, v4, v0
	and.16b	v16, v16, v19
	orr.16b	v6, v6, v16
	add.4s	v4, v4, v17
	bif.16b	v4, v17, v5
	fadd.4s	v4, v4, v7
	fabs.4s	v4, v4
	bif.16b	v4, v6, v5
	sshll.4s	v2, v2, #0
	and.16b	v2, v2, v18
	orr.16b	v16, v4, v2
	ldr	d2, [x16, x8]
	ushll.4s	v4, v2, #13
	and.16b	v5, v4, v0
	bic.4s	v4, #16, lsl #24
	cmeq.4s	v6, v5, v0
	cmeq.4s	v5, v5, #0
	and.16b	v6, v6, v23
	add.4s	v20, v4, v23
	add.4s	v6, v20, v6
	cmhi.4s	v20, v4, v0
	and.16b	v20, v20, v19
	orr.16b	v6, v6, v20
	add.4s	v4, v4, v17
	bif.16b	v4, v17, v5
	fadd.4s	v4, v4, v7
	fabs.4s	v4, v4
	bif.16b	v4, v6, v5
	sshll.4s	v2, v2, #0
	and.16b	v2, v2, v18
	orr.16b	v15, v4, v2
	ldr	d2, [x15, x8]
	ushll.4s	v4, v2, #13
	and.16b	v5, v4, v0
	bic.4s	v4, #16, lsl #24
	cmeq.4s	v6, v5, v0
	cmeq.4s	v5, v5, #0
	and.16b	v6, v6, v23
	add.4s	v23, v4, v23
	mov.16b	v1, v8
	mov.16b	v20, v10
	mov.16b	v8, v11
	ldp	q10, q11, [sp, #400]            ; 32-byte Folded Reload
	add.4s	v6, v23, v6
	cmhi.4s	v23, v4, v0
	and.16b	v23, v23, v19
	mov.16b	v19, v31
	mov.16b	v31, v30
	mov.16b	v30, v12
	ldr	q12, [sp, #384]                 ; 16-byte Folded Reload
	mov.16b	v0, v16
	mov.16b	v16, v25
	mov.16b	v25, v27
	mov.16b	v27, v1
	orr.16b	v6, v6, v23
	add.4s	v4, v4, v17
	bif.16b	v4, v17, v5
	fadd.4s	v4, v4, v7
	mov.16b	v7, v28
	mov.16b	v28, v24
	mov.16b	v24, v13
	fabs.4s	v4, v4
	bif.16b	v4, v6, v5
	movi.4h	v6, #124, lsl #8
	sshll.4s	v2, v2, #0
	and.16b	v2, v2, v18
	mov.16b	v23, v22
	mov.16b	v22, v26
	mov.16b	v26, v29
	mov.16b	v29, v9
	ldr	q9, [sp, #368]                  ; 16-byte Folded Reload
	mov.16b	v18, v14
	ldp	q1, q14, [sp, #432]             ; 32-byte Folded Reload
LBB2_22:                                ;   in Loop: Header=BB2_18 Depth=3
	orr.16b	v13, v4, v2
	b	LBB2_17
LBB2_23:                                ;   in Loop: Header=BB2_6 Depth=2
	mov	x24, #0                         ; =0x0
	movi.2d	v7, #0000000000000000
	movi.2d	v21, #0000000000000000
	mov	x4, x11
	movi.2d	v23, #0000000000000000
	mov	x22, x28
	movi.2d	v28, #0000000000000000
	movi.2d	v16, #0000000000000000
	movi.2d	v22, #0000000000000000
	movi.2d	v24, #0000000000000000
	movi.2d	v25, #0000000000000000
	movi.2d	v26, #0000000000000000
	movi.2d	v27, #0000000000000000
	movi.2d	v19, #0000000000000000
	movi.2d	v29, #0000000000000000
	movi.2d	v31, #0000000000000000
	movi.2d	v30, #0000000000000000
	movi.2d	v9, #0000000000000000
	movi.2d	v20, #0000000000000000
	movi.2d	v8, #0000000000000000
	movi.2d	v11, #0000000000000000
	movi.2d	v12, #0000000000000000
	movi.2d	v18, #0000000000000000
	movi.2d	v10, #0000000000000000
	movi.2d	v1, #0000000000000000
	str	q1, [sp, #480]                  ; 16-byte Folded Spill
	movi.2d	v14, #0000000000000000
	b	LBB2_26
LBB2_24:                                ;   in Loop: Header=BB2_26 Depth=3
	ldr	q5, [sp, #464]                  ; 16-byte Folded Reload
LBB2_25:                                ;   in Loop: Header=BB2_26 Depth=3
	add	x27, x24, #4
	add	x22, x22, #16
	add	x4, x4, #8
	add	x8, x24, #8
	mov	x24, x27
	cmp	x8, x3
	b.gt	LBB2_8
LBB2_26:                                ;   Parent Loop BB2_4 Depth=1
                                        ;     Parent Loop BB2_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	cmp	x6, #1
	b.lt	LBB2_25
; %bb.27:                               ;   in Loop: Header=BB2_26 Depth=3
	cbz	w0, LBB2_33
; %bb.28:                               ;   in Loop: Header=BB2_26 Depth=3
	cmp	w0, #2
	b.ne	LBB2_37
; %bb.29:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	d2, [x4]
	fmov	d3, d2
	bic.4h	v3, #128, lsl #8
	cmhi.4h	v3, v3, v6
	movi.4h	v5, #2, lsl #8
	and.8b	v3, v3, v5
	orr.8b	v2, v3, v2
	fcvtl	v3.4s, v2.4h
	cmp	x10, #2
	b.lt	LBB2_44
; %bb.30:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	d2, [x4, x12]
	fmov	d4, d2
	bic.4h	v4, #128, lsl #8
	cmhi.4h	v4, v4, v6
	and.8b	v4, v4, v5
	orr.8b	v2, v4, v2
	fcvtl	v0.4s, v2.4h
	cmp	x10, #2
	b.eq	LBB2_44
; %bb.31:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	x8, [sp, #256]                  ; 8-byte Folded Reload
	ldr	d2, [x4, x8]
	fmov	d4, d2
	bic.4h	v4, #128, lsl #8
	cmhi.4h	v4, v4, v6
	and.8b	v4, v4, v5
	orr.8b	v2, v4, v2
	fcvtl	v15.4s, v2.4h
	cmp	x10, #3
	b.eq	LBB2_44
; %bb.32:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	x8, [sp, #160]                  ; 8-byte Folded Reload
	ldr	d2, [x4, x8]
	fmov	d4, d2
	bic.4h	v4, #128, lsl #8
	cmhi.4h	v4, v4, v6
	and.8b	v4, v4, v5
	orr.8b	v2, v4, v2
	fcvtl	v13.4s, v2.4h
	cmp	x13, #1
	b.ge	LBB2_45
	b	LBB2_24
LBB2_33:                                ;   in Loop: Header=BB2_26 Depth=3
	ldr	d2, [x4]
	ushll.4s	v3, v2, #0
	shll.4s	v2, v2, #16
	bic.4s	v3, #128, lsl #8
	cmhi.4s	v3, v3, v5
	movi.4s	v6, #64, lsl #16
	and.16b	v3, v3, v6
	orr.16b	v3, v3, v2
	cmp	x10, #1
	b.le	LBB2_36
; %bb.34:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	d2, [x4, x12]
	ushll.4s	v4, v2, #0
	shll.4s	v2, v2, #16
	bic.4s	v4, #128, lsl #8
	cmhi.4s	v4, v4, v5
	and.16b	v4, v4, v6
	orr.16b	v0, v4, v2
	cmp	x10, #2
	b.eq	LBB2_36
; %bb.35:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	x8, [sp, #256]                  ; 8-byte Folded Reload
	ldr	d2, [x4, x8]
	ushll.4s	v4, v2, #0
	shll.4s	v2, v2, #16
	bic.4s	v4, #128, lsl #8
	cmhi.4s	v4, v4, v5
	and.16b	v4, v4, v6
	orr.16b	v15, v4, v2
	cmp	x10, #3
	b.ne	LBB2_74
LBB2_36:                                ;   in Loop: Header=BB2_26 Depth=3
	movi.4h	v6, #124, lsl #8
	cmp	x13, #1
	b.ge	LBB2_45
	b	LBB2_24
LBB2_37:                                ;   in Loop: Header=BB2_26 Depth=3
	stp	q1, q14, [sp, #432]             ; 32-byte Folded Spill
	stp	q12, q10, [sp, #384]            ; 32-byte Folded Spill
	str	q18, [sp, #320]                 ; 16-byte Folded Spill
	str	q11, [sp, #416]                 ; 16-byte Folded Spill
	mov.16b	v14, v8
	mov.16b	v1, v9
	mov.16b	v10, v20
	mov.16b	v12, v30
	mov.16b	v30, v31
	mov.16b	v9, v29
	mov.16b	v31, v19
	mov.16b	v8, v27
	mov.16b	v29, v26
	mov.16b	v27, v25
	mov.16b	v3, v28
	mov.16b	v28, v24
	mov.16b	v26, v22
	mov.16b	v25, v16
	mov.16b	v24, v3
	mov.16b	v22, v23
	mov.16b	v19, v7
	ldr	d2, [x4]
	ushll.4s	v3, v2, #13
	ldp	q20, q23, [sp, #336]            ; 32-byte Folded Reload
	and.16b	v4, v3, v23
	bic.4s	v3, #16, lsl #24
	cmeq.4s	v5, v4, v23
	cmeq.4s	v4, v4, #0
	movi.4s	v11, #56, lsl #24
	and.16b	v5, v5, v11
	add.4s	v6, v3, v11
	add.4s	v5, v6, v5
	cmhi.4s	v6, v3, v23
	movi.4s	v7, #64, lsl #16
	and.16b	v6, v6, v7
	orr.16b	v5, v5, v6
	add.4s	v3, v3, v17
	bif.16b	v3, v17, v4
	fadd.4s	v3, v3, v20
	fabs.4s	v3, v3
	bif.16b	v3, v5, v4
	sshll.4s	v2, v2, #0
	movi.4s	v18, #128, lsl #24
	and.16b	v2, v2, v18
	orr.16b	v3, v3, v2
	cmp	x10, #2
	b.ge	LBB2_39
; %bb.38:                               ;   in Loop: Header=BB2_26 Depth=3
	movi.4h	v6, #124, lsl #8
	mov.16b	v7, v19
	mov.16b	v23, v22
	mov.16b	v4, v24
	mov.16b	v16, v25
	mov.16b	v22, v26
	mov.16b	v24, v28
	mov.16b	v28, v4
	mov.16b	v25, v27
	mov.16b	v26, v29
	mov.16b	v27, v8
	mov.16b	v19, v31
	mov.16b	v29, v9
	mov.16b	v31, v30
	mov.16b	v30, v12
	mov.16b	v20, v10
	mov.16b	v9, v1
	mov.16b	v8, v14
	ldp	q10, q11, [sp, #400]            ; 32-byte Folded Reload
	ldr	q12, [sp, #384]                 ; 16-byte Folded Reload
	b	LBB2_43
LBB2_39:                                ;   in Loop: Header=BB2_26 Depth=3
	ldr	d4, [x4, x12]
	ushll.4s	v16, v4, #13
	and.16b	v2, v16, v23
	bic.4s	v16, #16, lsl #24
	cmeq.4s	v5, v2, v23
	cmeq.4s	v2, v2, #0
	and.16b	v5, v5, v11
	add.4s	v6, v16, v11
	add.4s	v5, v6, v5
	cmhi.4s	v6, v16, v23
	and.16b	v6, v6, v7
	orr.16b	v5, v5, v6
	add.4s	v6, v16, v17
	bif.16b	v6, v17, v2
	fadd.4s	v6, v6, v20
	fabs.4s	v6, v6
	bsl.16b	v2, v6, v5
	sshll.4s	v4, v4, #0
	and.16b	v4, v4, v18
	orr.16b	v0, v2, v4
	str	q0, [sp, #368]                  ; 16-byte Folded Spill
	cmp	x10, #2
	b.eq	LBB2_42
; %bb.40:                               ;   in Loop: Header=BB2_26 Depth=3
	mov.16b	v0, v20
	ldr	x8, [sp, #256]                  ; 8-byte Folded Reload
	ldr	d2, [x4, x8]
	ushll.4s	v4, v2, #13
	and.16b	v5, v4, v23
	bic.4s	v4, #16, lsl #24
	cmeq.4s	v6, v5, v23
	cmeq.4s	v5, v5, #0
	and.16b	v6, v6, v11
	add.4s	v20, v4, v11
	add.4s	v6, v20, v6
	cmhi.4s	v20, v4, v23
	and.16b	v20, v20, v7
	orr.16b	v6, v6, v20
	add.4s	v4, v4, v17
	bif.16b	v4, v17, v5
	fadd.4s	v4, v4, v0
	fabs.4s	v4, v4
	bif.16b	v4, v6, v5
	sshll.4s	v2, v2, #0
	and.16b	v2, v2, v18
	orr.16b	v15, v4, v2
	cmp	x10, #3
	b.eq	LBB2_42
; %bb.41:                               ;   in Loop: Header=BB2_26 Depth=3
	mov.16b	v16, v0
	ldr	x8, [sp, #160]                  ; 8-byte Folded Reload
	ldr	d2, [x4, x8]
	ushll.4s	v4, v2, #13
	and.16b	v5, v4, v23
	bic.4s	v4, #16, lsl #24
	cmeq.4s	v6, v5, v23
	cmeq.4s	v5, v5, #0
	and.16b	v6, v6, v11
	mov.16b	v0, v23
	add.4s	v23, v4, v11
	add.4s	v6, v23, v6
	cmhi.4s	v23, v4, v0
	and.16b	v23, v23, v7
	orr.16b	v6, v6, v23
	add.4s	v4, v4, v17
	bif.16b	v4, v17, v5
	fadd.4s	v4, v4, v16
	fabs.4s	v4, v4
	bif.16b	v4, v6, v5
	sshll.4s	v2, v2, #0
	and.16b	v2, v2, v18
	orr.16b	v13, v4, v2
LBB2_42:                                ;   in Loop: Header=BB2_26 Depth=3
	movi.4h	v6, #124, lsl #8
	mov.16b	v7, v19
	mov.16b	v23, v22
	mov.16b	v0, v24
	mov.16b	v16, v25
	mov.16b	v22, v26
	mov.16b	v24, v28
	mov.16b	v28, v0
	mov.16b	v25, v27
	mov.16b	v26, v29
	mov.16b	v27, v8
	mov.16b	v19, v31
	mov.16b	v29, v9
	mov.16b	v31, v30
	mov.16b	v30, v12
	mov.16b	v20, v10
	mov.16b	v9, v1
	mov.16b	v8, v14
	ldp	q10, q11, [sp, #400]            ; 32-byte Folded Reload
	ldp	q0, q12, [sp, #368]             ; 32-byte Folded Reload
LBB2_43:                                ;   in Loop: Header=BB2_26 Depth=3
	ldr	q18, [sp, #320]                 ; 16-byte Folded Reload
	ldp	q1, q14, [sp, #432]             ; 32-byte Folded Reload
LBB2_44:                                ;   in Loop: Header=BB2_26 Depth=3
	cmp	x13, #1
	b.lt	LBB2_24
LBB2_45:                                ;   in Loop: Header=BB2_26 Depth=3
	ldr	q4, [x22]
	cmp	x10, #2
	ldr	q5, [sp, #464]                  ; 16-byte Folded Reload
	b.lt	LBB2_49
; %bb.46:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v1, v0, v4
	b.eq	LBB2_49
; %bb.47:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	q2, [sp, #480]                  ; 16-byte Folded Reload
	fmla.4s	v2, v15, v4
	str	q2, [sp, #480]                  ; 16-byte Folded Spill
	cmp	x10, #3
	b.eq	LBB2_49
; %bb.48:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v10, v13, v4
LBB2_49:                                ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v14, v3, v4
	cmp	x2, #2
	b.lt	LBB2_25
; %bb.50:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	q4, [x22, x9]
	cmp	x10, #2
	b.lt	LBB2_54
; %bb.51:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v12, v0, v4
	b.eq	LBB2_54
; %bb.52:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v11, v15, v4
	cmp	x10, #3
	b.eq	LBB2_54
; %bb.53:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v8, v13, v4
LBB2_54:                                ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v18, v3, v4
	cmp	x2, #2
	b.eq	LBB2_25
; %bb.55:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	x8, [sp, #184]                  ; 8-byte Folded Reload
	ldr	q4, [x22, x8]
	cmp	x10, #2
	b.lt	LBB2_59
; %bb.56:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v9, v0, v4
	b.eq	LBB2_59
; %bb.57:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v30, v15, v4
	cmp	x10, #3
	b.eq	LBB2_59
; %bb.58:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v31, v13, v4
LBB2_59:                                ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v20, v3, v4
	cmp	x2, #3
	b.eq	LBB2_25
; %bb.60:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	x8, [sp, #128]                  ; 8-byte Folded Reload
	ldr	q4, [x22, x8]
	cmp	x10, #2
	b.lt	LBB2_64
; %bb.61:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v19, v0, v4
	b.eq	LBB2_64
; %bb.62:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v27, v15, v4
	cmp	x10, #3
	b.eq	LBB2_64
; %bb.63:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v26, v13, v4
LBB2_64:                                ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v29, v3, v4
	cmp	x2, #4
	b.eq	LBB2_25
; %bb.65:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	x8, [sp, #104]                  ; 8-byte Folded Reload
	ldr	q4, [x22, x8, lsl #4]
	cmp	x10, #2
	b.lt	LBB2_69
; %bb.66:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v24, v0, v4
	b.eq	LBB2_69
; %bb.67:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v22, v15, v4
	cmp	x10, #3
	b.eq	LBB2_69
; %bb.68:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v16, v13, v4
LBB2_69:                                ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v25, v3, v4
	cmp	x2, #5
	b.eq	LBB2_25
; %bb.70:                               ;   in Loop: Header=BB2_26 Depth=3
	ldr	x8, [sp, #88]                   ; 8-byte Folded Reload
	ldr	q4, [x22, x8]
	fmla.4s	v28, v3, v4
	cmp	x10, #2
	b.lt	LBB2_25
; %bb.71:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v23, v0, v4
	b.eq	LBB2_25
; %bb.72:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v21, v15, v4
	cmp	x10, #3
	b.eq	LBB2_25
; %bb.73:                               ;   in Loop: Header=BB2_26 Depth=3
	fmla.4s	v7, v13, v4
	b	LBB2_25
LBB2_74:                                ;   in Loop: Header=BB2_26 Depth=3
	ldr	x8, [sp, #160]                  ; 8-byte Folded Reload
	ldr	d2, [x4, x8]
	ushll.4s	v4, v2, #0
	shll.4s	v2, v2, #16
	bic.4s	v4, #128, lsl #8
	cmhi.4s	v4, v4, v5
	and.16b	v4, v4, v6
	orr.16b	v13, v4, v2
	movi.4h	v6, #124, lsl #8
	cmp	x13, #1
	b.ge	LBB2_45
	b	LBB2_24
LBB2_75:                                ;   in Loop: Header=BB2_6 Depth=2
	b.lt	LBB2_5
; %bb.76:                               ;   in Loop: Header=BB2_6 Depth=2
	mov	x8, #0                          ; =0x0
	str	s1, [sp, #464]                  ; 4-byte Folded Spill
	lsl	x12, x27, #2
	str	s1, [sp, #400]                  ; 4-byte Folded Spill
	add	x14, x20, x12
	str	x14, [sp, #144]                 ; 8-byte Folded Spill
	str	s1, [sp, #352]                  ; 4-byte Folded Spill
	add	x14, x7, x12
	str	x14, [sp, #152]                 ; 8-byte Folded Spill
	add	x14, x19, x12
	str	x14, [sp, #240]                 ; 8-byte Folded Spill
	add	x21, x5, x12
	str	s1, [sp, #384]                  ; 4-byte Folded Spill
	ldr	x14, [sp, #312]                 ; 8-byte Folded Reload
	add	x22, x14, x12
	str	s1, [sp, #304]                  ; 4-byte Folded Spill
	add	x25, x28, x12
	lsl	x14, x27, #1
	add	x12, x15, x14
	str	x12, [sp, #232]                 ; 8-byte Folded Spill
	add	x30, x16, x14
	str	s1, [sp, #288]                  ; 4-byte Folded Spill
	add	x12, x17, x14
	add	x14, x11, x14
	str	s2, [sp, #308]                  ; 4-byte Folded Spill
	str	s2, [sp, #292]                  ; 4-byte Folded Spill
	str	s2, [sp, #276]                  ; 4-byte Folded Spill
	str	s2, [sp, #320]                  ; 4-byte Folded Spill
	str	s2, [sp, #300]                  ; 4-byte Folded Spill
	str	s2, [sp, #284]                  ; 4-byte Folded Spill
	str	s2, [sp, #268]                  ; 4-byte Folded Spill
	str	s2, [sp, #296]                  ; 4-byte Folded Spill
	str	s2, [sp, #280]                  ; 4-byte Folded Spill
	str	s2, [sp, #272]                  ; 4-byte Folded Spill
	str	s2, [sp, #252]                  ; 4-byte Folded Spill
	b	LBB2_138
LBB2_77:                                ;   in Loop: Header=BB2_79 Depth=3
	ldr	s17, [sp, #124]                 ; 4-byte Folded Reload
	fmov	s21, s15
	ldr	s15, [sp, #100]                 ; 4-byte Folded Reload
LBB2_78:                                ;   in Loop: Header=BB2_79 Depth=3
	fadd	s0, s0, s2
	add	x4, x4, #1
	cmp	x24, x4
	b.eq	LBB2_171
LBB2_79:                                ;   Parent Loop BB2_4 Depth=1
                                        ;     Parent Loop BB2_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldrsh	w30, [x12, x4, lsl #1]
	and	w23, w30, #0xffff
	and	w8, w30, #0x80000000
	and	w21, w30, #0x3ff
	ubfx	w30, w30, #10, #5
	cmp	w30, #31
	b.eq	LBB2_85
; %bb.80:                               ;   in Loop: Header=BB2_79 Depth=3
	cbnz	w30, LBB2_83
; %bb.81:                               ;   in Loop: Header=BB2_79 Depth=3
	cbz	w21, LBB2_84
; %bb.82:                               ;   in Loop: Header=BB2_79 Depth=3
	clz	w21, w21
	eor	w30, w21, #0x1f
	mov	w1, #10                         ; =0xa
	sub	w30, w1, w30
	lsl	w23, w23, w30
	mov	w1, #22                         ; =0x16
	sub	w30, w1, w21
	and	w21, w23, #0x3fe
LBB2_83:                                ;   in Loop: Header=BB2_79 Depth=3
	lsl	w21, w21, #13
	orr	w21, w21, w30, lsl #23
	mov	w1, #939524096                  ; =0x38000000
	add	w21, w21, w1
	orr	w8, w21, w8
LBB2_84:                                ;   in Loop: Header=BB2_79 Depth=3
	fmov	s2, w8
	cmp	x2, #2
	b.ge	LBB2_86
	b	LBB2_91
LBB2_85:                                ;   in Loop: Header=BB2_79 Depth=3
	lsl	w23, w23, #13
	cmp	w21, #0
	cset	w21, ne
	orr	w21, w23, w21, lsl #22
	orr	w8, w21, w8
	orr	w8, w8, #0x7f800000
	fmov	s2, w8
	cmp	x2, #2
	b.lt	LBB2_91
LBB2_86:                                ;   in Loop: Header=BB2_79 Depth=3
	ldr	s3, [x22, x4, lsl #2]
	fmul	s3, s3, s2
	fadd	s11, s11, s3
	cmp	x2, #2
	b.eq	LBB2_91
; %bb.87:                               ;   in Loop: Header=BB2_79 Depth=3
	ldr	s3, [x14, x4, lsl #2]
	fmul	s3, s3, s2
	fadd	s4, s4, s3
	cmp	x2, #3
	b.eq	LBB2_91
; %bb.88:                               ;   in Loop: Header=BB2_79 Depth=3
	ldr	x8, [sp, #232]                  ; 8-byte Folded Reload
	ldr	s3, [x8, x4, lsl #2]
	fmul	s3, s3, s2
	fadd	s17, s17, s3
	cmp	x2, #4
	b.eq	LBB2_91
; %bb.89:                               ;   in Loop: Header=BB2_79 Depth=3
	ldr	x8, [sp, #144]                  ; 8-byte Folded Reload
	ldr	s3, [x8, x4, lsl #2]
	fmul	s3, s3, s2
	ldr	s5, [sp, #320]                  ; 4-byte Folded Reload
	fadd	s5, s5, s3
	str	s5, [sp, #320]                  ; 4-byte Folded Spill
	cmp	x2, #5
	b.eq	LBB2_91
; %bb.90:                               ;   in Loop: Header=BB2_79 Depth=3
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	ldr	s3, [x8, x4, lsl #2]
	fmul	s3, s3, s2
	ldr	s5, [sp, #296]                  ; 4-byte Folded Reload
	fadd	s5, s5, s3
	str	s5, [sp, #296]                  ; 4-byte Folded Spill
LBB2_91:                                ;   in Loop: Header=BB2_79 Depth=3
	ldr	s3, [x25, x4, lsl #2]
	fmul	s2, s3, s2
	cmp	x10, #2
	b.lt	LBB2_78
; %bb.92:                               ;   in Loop: Header=BB2_79 Depth=3
	ldrsh	w30, [x27, x4, lsl #1]
	and	w23, w30, #0xffff
	and	w8, w30, #0x80000000
	and	w21, w30, #0x3ff
	ubfx	w30, w30, #10, #5
	cmp	w30, #31
	b.eq	LBB2_98
; %bb.93:                               ;   in Loop: Header=BB2_79 Depth=3
	cbnz	w30, LBB2_96
; %bb.94:                               ;   in Loop: Header=BB2_79 Depth=3
	cbz	w21, LBB2_97
; %bb.95:                               ;   in Loop: Header=BB2_79 Depth=3
	clz	w21, w21
	eor	w30, w21, #0x1f
	mov	w1, #10                         ; =0xa
	sub	w30, w1, w30
	lsl	w23, w23, w30
	mov	w1, #22                         ; =0x16
	sub	w30, w1, w21
	and	w21, w23, #0x3fe
LBB2_96:                                ;   in Loop: Header=BB2_79 Depth=3
	lsl	w21, w21, #13
	orr	w21, w21, w30, lsl #23
	mov	w1, #939524096                  ; =0x38000000
	add	w21, w21, w1
	orr	w8, w21, w8
LBB2_97:                                ;   in Loop: Header=BB2_79 Depth=3
	fmov	s3, w8
	cmp	x2, #2
	b.ge	LBB2_99
	b	LBB2_106
LBB2_98:                                ;   in Loop: Header=BB2_79 Depth=3
	lsl	w23, w23, #13
	cmp	w21, #0
	cset	w21, ne
	orr	w21, w23, w21, lsl #22
	orr	w8, w21, w8
	orr	w8, w8, #0x7f800000
	fmov	s3, w8
	cmp	x2, #2
	b.lt	LBB2_106
LBB2_99:                                ;   in Loop: Header=BB2_79 Depth=3
	ldr	s5, [x22, x4, lsl #2]
	fmul	s5, s5, s3
	fadd	s14, s14, s5
	cmp	x2, #2
	b.eq	LBB2_106
; %bb.100:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	s5, [x14, x4, lsl #2]
	fmul	s5, s5, s3
	fadd	s15, s15, s5
	cmp	x2, #3
	b.eq	LBB2_106
; %bb.101:                              ;   in Loop: Header=BB2_79 Depth=3
	fmov	s1, s4
	fmov	s4, s15
	fmov	s15, s21
	ldr	x8, [sp, #232]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s21, [sp, #308]                 ; 4-byte Folded Reload
	fadd	s21, s21, s5
	str	s21, [sp, #308]                 ; 4-byte Folded Spill
	cmp	x2, #4
	b.ne	LBB2_103
; %bb.102:                              ;   in Loop: Header=BB2_79 Depth=3
	fmov	s21, s15
	fmov	s15, s4
	fmov	s4, s1
	movi.4h	v6, #124, lsl #8
	b	LBB2_106
LBB2_103:                               ;   in Loop: Header=BB2_79 Depth=3
	str	s11, [sp, #124]                 ; 4-byte Folded Spill
	fmov	s11, s14
	ldr	x8, [sp, #144]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #300]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #300]                 ; 4-byte Folded Spill
	cmp	x2, #5
	b.eq	LBB2_105
; %bb.104:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #280]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #280]                 ; 4-byte Folded Spill
LBB2_105:                               ;   in Loop: Header=BB2_79 Depth=3
	fmov	s21, s15
	fmov	s15, s4
	fmov	s4, s1
	movi.4h	v6, #124, lsl #8
	fmov	s14, s11
	ldr	s11, [sp, #124]                 ; 4-byte Folded Reload
LBB2_106:                               ;   in Loop: Header=BB2_79 Depth=3
	ldr	s5, [x25, x4, lsl #2]
	fmul	s3, s5, s3
	ldr	s1, [sp, #464]                  ; 4-byte Folded Reload
	fadd	s1, s1, s3
	str	s1, [sp, #464]                  ; 4-byte Folded Spill
	cmp	x10, #2
	b.eq	LBB2_78
; %bb.107:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	x8, [sp, #240]                  ; 8-byte Folded Reload
	ldrsh	w30, [x8, x4, lsl #1]
	and	w23, w30, #0xffff
	and	w8, w30, #0x80000000
	and	w21, w30, #0x3ff
	ubfx	w30, w30, #10, #5
	cmp	w30, #31
	b.eq	LBB2_113
; %bb.108:                              ;   in Loop: Header=BB2_79 Depth=3
	cbnz	w30, LBB2_111
; %bb.109:                              ;   in Loop: Header=BB2_79 Depth=3
	cbz	w21, LBB2_112
; %bb.110:                              ;   in Loop: Header=BB2_79 Depth=3
	clz	w21, w21
	eor	w30, w21, #0x1f
	mov	w1, #10                         ; =0xa
	sub	w30, w1, w30
	lsl	w23, w23, w30
	mov	w1, #22                         ; =0x16
	sub	w30, w1, w21
	and	w21, w23, #0x3fe
LBB2_111:                               ;   in Loop: Header=BB2_79 Depth=3
	lsl	w21, w21, #13
	orr	w21, w21, w30, lsl #23
	mov	w1, #939524096                  ; =0x38000000
	add	w21, w21, w1
	orr	w8, w21, w8
LBB2_112:                               ;   in Loop: Header=BB2_79 Depth=3
	fmov	s3, w8
	cmp	x2, #2
	b.ge	LBB2_114
	b	LBB2_122
LBB2_113:                               ;   in Loop: Header=BB2_79 Depth=3
	lsl	w23, w23, #13
	cmp	w21, #0
	cset	w21, ne
	orr	w21, w23, w21, lsl #22
	orr	w8, w21, w8
	orr	w8, w8, #0x7f800000
	fmov	s3, w8
	cmp	x2, #2
	b.lt	LBB2_122
LBB2_114:                               ;   in Loop: Header=BB2_79 Depth=3
	fmov	s1, s14
	ldr	s5, [x22, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #384]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #384]                 ; 4-byte Folded Spill
	cmp	x2, #2
	b.eq	LBB2_121
; %bb.115:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	s5, [x14, x4, lsl #2]
	fmul	s5, s5, s3
	fadd	s21, s21, s5
	cmp	x2, #3
	b.eq	LBB2_121
; %bb.116:                              ;   in Loop: Header=BB2_79 Depth=3
	str	s21, [sp, #124]                 ; 4-byte Folded Spill
	ldr	x8, [sp, #232]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #292]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #292]                 ; 4-byte Folded Spill
	cmp	x2, #4
	b.ne	LBB2_118
; %bb.117:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	s21, [sp, #124]                 ; 4-byte Folded Reload
	b	LBB2_121
LBB2_118:                               ;   in Loop: Header=BB2_79 Depth=3
	fmov	s6, s4
	fmov	s4, s15
	fmov	s14, s17
	ldr	x8, [sp, #144]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s15, [sp, #284]                 ; 4-byte Folded Reload
	fadd	s15, s15, s5
	str	s15, [sp, #284]                 ; 4-byte Folded Spill
	cmp	x2, #5
	b.eq	LBB2_120
; %bb.119:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s5, s5, s3
	fmov	s15, s11
	ldr	s11, [sp, #272]                 ; 4-byte Folded Reload
	fadd	s11, s11, s5
	str	s11, [sp, #272]                 ; 4-byte Folded Spill
	fmov	s11, s15
LBB2_120:                               ;   in Loop: Header=BB2_79 Depth=3
	fmov	s17, s14
	ldr	s21, [sp, #124]                 ; 4-byte Folded Reload
	fmov	s15, s4
	fmov	s4, s6
	movi.4h	v6, #124, lsl #8
LBB2_121:                               ;   in Loop: Header=BB2_79 Depth=3
	fmov	s14, s1
LBB2_122:                               ;   in Loop: Header=BB2_79 Depth=3
	ldr	s5, [x25, x4, lsl #2]
	fmul	s3, s5, s3
	ldr	s1, [sp, #400]                  ; 4-byte Folded Reload
	fadd	s1, s1, s3
	str	s1, [sp, #400]                  ; 4-byte Folded Spill
	cmp	x10, #3
	b.eq	LBB2_78
; %bb.123:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	x8, [sp, #152]                  ; 8-byte Folded Reload
	ldrsh	w30, [x8, x4, lsl #1]
	and	w23, w30, #0xffff
	and	w8, w30, #0x80000000
	and	w21, w30, #0x3ff
	ubfx	w30, w30, #10, #5
	cmp	w30, #31
	b.eq	LBB2_128
; %bb.124:                              ;   in Loop: Header=BB2_79 Depth=3
	cbnz	w30, LBB2_127
; %bb.125:                              ;   in Loop: Header=BB2_79 Depth=3
	cbz	w21, LBB2_129
; %bb.126:                              ;   in Loop: Header=BB2_79 Depth=3
	clz	w21, w21
	eor	w30, w21, #0x1f
	mov	w1, #10                         ; =0xa
	sub	w30, w1, w30
	lsl	w23, w23, w30
	mov	w1, #22                         ; =0x16
	sub	w30, w1, w21
	and	w21, w23, #0x3fe
LBB2_127:                               ;   in Loop: Header=BB2_79 Depth=3
	lsl	w21, w21, #13
	orr	w21, w21, w30, lsl #23
	mov	w1, #939524096                  ; =0x38000000
	add	w21, w21, w1
	orr	w8, w21, w8
	b	LBB2_129
LBB2_128:                               ;   in Loop: Header=BB2_79 Depth=3
	lsl	w23, w23, #13
	cmp	w21, #0
	cset	w21, ne
	orr	w21, w23, w21, lsl #22
	orr	w8, w21, w8
	orr	w8, w8, #0x7f800000
LBB2_129:                               ;   in Loop: Header=BB2_79 Depth=3
	fmov	s3, w8
	ldr	s5, [x25, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s1, [sp, #352]                  ; 4-byte Folded Reload
	fadd	s1, s1, s5
	str	s1, [sp, #352]                  ; 4-byte Folded Spill
	cmp	x2, #2
	b.lt	LBB2_78
; %bb.130:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	s5, [x22, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s1, [sp, #304]                  ; 4-byte Folded Reload
	fadd	s1, s1, s5
	str	s1, [sp, #304]                  ; 4-byte Folded Spill
	cmp	x2, #2
	b.eq	LBB2_78
; %bb.131:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	s5, [x14, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s1, [sp, #288]                  ; 4-byte Folded Reload
	fadd	s1, s1, s5
	str	s1, [sp, #288]                  ; 4-byte Folded Spill
	cmp	x2, #3
	b.eq	LBB2_78
; %bb.132:                              ;   in Loop: Header=BB2_79 Depth=3
	str	s15, [sp, #100]                 ; 4-byte Folded Spill
	fmov	s15, s21
	str	s17, [sp, #124]                 ; 4-byte Folded Spill
	ldr	x8, [sp, #232]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s21, [sp, #276]                 ; 4-byte Folded Reload
	fadd	s21, s21, s5
	str	s21, [sp, #276]                 ; 4-byte Folded Spill
	cmp	x2, #4
	b.eq	LBB2_77
; %bb.133:                              ;   in Loop: Header=BB2_79 Depth=3
	fmov	s1, s14
	ldr	x8, [sp, #144]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #268]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #268]                 ; 4-byte Folded Spill
	cmp	x2, #5
	fmov	s21, s15
	b.eq	LBB2_135
; %bb.134:                              ;   in Loop: Header=BB2_79 Depth=3
	ldr	x8, [sp, #112]                  ; 8-byte Folded Reload
	ldr	s5, [x8, x4, lsl #2]
	fmul	s3, s5, s3
	ldr	s5, [sp, #252]                  ; 4-byte Folded Reload
	fadd	s5, s5, s3
	str	s5, [sp, #252]                  ; 4-byte Folded Spill
LBB2_135:                               ;   in Loop: Header=BB2_79 Depth=3
	ldr	s17, [sp, #124]                 ; 4-byte Folded Reload
	ldr	s15, [sp, #100]                 ; 4-byte Folded Reload
	fmov	s14, s1
	b	LBB2_78
LBB2_136:                               ;   in Loop: Header=BB2_138 Depth=3
	ldr	s17, [sp, #124]                 ; 4-byte Folded Reload
	fmov	s21, s15
	ldr	s15, [sp, #100]                 ; 4-byte Folded Reload
LBB2_137:                               ;   in Loop: Header=BB2_138 Depth=3
	fadd	s0, s0, s2
	add	x8, x8, #1
	cmp	x24, x8
	b.eq	LBB2_171
LBB2_138:                               ;   Parent Loop BB2_4 Depth=1
                                        ;     Parent Loop BB2_6 Depth=2
                                        ; =>    This Inner Loop Header: Depth=3
	ldrh	w23, [x14, x8, lsl #1]
	lsl	w27, w23, #16
	and	w23, w23, #0x7fff
	orr	w4, w27, #0x400000
	cmp	w23, w1
	csel	w4, w4, w27, hi
	fmov	s2, w4
	cmp	x2, #2
	b.lt	LBB2_144
; %bb.139:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	s3, [x22, x8, lsl #2]
	fmul	s3, s3, s2
	fadd	s11, s11, s3
	cmp	x2, #2
	b.eq	LBB2_144
; %bb.140:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	s3, [x21, x8, lsl #2]
	fmul	s3, s3, s2
	fadd	s4, s4, s3
	cmp	x2, #3
	b.eq	LBB2_144
; %bb.141:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	x4, [sp, #240]                  ; 8-byte Folded Reload
	ldr	s3, [x4, x8, lsl #2]
	fmul	s3, s3, s2
	fadd	s17, s17, s3
	cmp	x2, #4
	b.eq	LBB2_144
; %bb.142:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	x4, [sp, #152]                  ; 8-byte Folded Reload
	ldr	s3, [x4, x8, lsl #2]
	fmul	s3, s3, s2
	ldr	s5, [sp, #320]                  ; 4-byte Folded Reload
	fadd	s5, s5, s3
	str	s5, [sp, #320]                  ; 4-byte Folded Spill
	cmp	x2, #5
	b.eq	LBB2_144
; %bb.143:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	x4, [sp, #144]                  ; 8-byte Folded Reload
	ldr	s3, [x4, x8, lsl #2]
	fmul	s3, s3, s2
	ldr	s5, [sp, #296]                  ; 4-byte Folded Reload
	fadd	s5, s5, s3
	str	s5, [sp, #296]                  ; 4-byte Folded Spill
LBB2_144:                               ;   in Loop: Header=BB2_138 Depth=3
	ldr	s3, [x25, x8, lsl #2]
	fmul	s2, s3, s2
	cmp	x10, #2
	b.lt	LBB2_137
; %bb.145:                              ;   in Loop: Header=BB2_138 Depth=3
	ldrh	w4, [x12, x8, lsl #1]
	lsl	w23, w4, #16
	and	w4, w4, #0x7fff
	orr	w27, w23, #0x400000
	cmp	w4, w1
	csel	w4, w27, w23, hi
	fmov	s3, w4
	cmp	x2, #2
	b.lt	LBB2_153
; %bb.146:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	s5, [x22, x8, lsl #2]
	fmul	s5, s5, s3
	fadd	s14, s14, s5
	cmp	x2, #2
	b.eq	LBB2_153
; %bb.147:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	s5, [x21, x8, lsl #2]
	fmul	s5, s5, s3
	fadd	s15, s15, s5
	cmp	x2, #3
	b.eq	LBB2_153
; %bb.148:                              ;   in Loop: Header=BB2_138 Depth=3
	fmov	s1, s4
	fmov	s4, s15
	fmov	s15, s21
	ldr	x4, [sp, #240]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s21, [sp, #308]                 ; 4-byte Folded Reload
	fadd	s21, s21, s5
	str	s21, [sp, #308]                 ; 4-byte Folded Spill
	cmp	x2, #4
	b.ne	LBB2_150
; %bb.149:                              ;   in Loop: Header=BB2_138 Depth=3
	fmov	s21, s15
	fmov	s15, s4
	fmov	s4, s1
	movi.4h	v6, #124, lsl #8
	b	LBB2_153
LBB2_150:                               ;   in Loop: Header=BB2_138 Depth=3
	str	s11, [sp, #124]                 ; 4-byte Folded Spill
	fmov	s11, s14
	ldr	x4, [sp, #152]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #300]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #300]                 ; 4-byte Folded Spill
	cmp	x2, #5
	b.eq	LBB2_152
; %bb.151:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	x4, [sp, #144]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #280]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #280]                 ; 4-byte Folded Spill
LBB2_152:                               ;   in Loop: Header=BB2_138 Depth=3
	fmov	s21, s15
	fmov	s15, s4
	fmov	s4, s1
	movi.4h	v6, #124, lsl #8
	fmov	s14, s11
	ldr	s11, [sp, #124]                 ; 4-byte Folded Reload
LBB2_153:                               ;   in Loop: Header=BB2_138 Depth=3
	ldr	s5, [x25, x8, lsl #2]
	fmul	s3, s5, s3
	ldr	s1, [sp, #464]                  ; 4-byte Folded Reload
	fadd	s1, s1, s3
	str	s1, [sp, #464]                  ; 4-byte Folded Spill
	cmp	x10, #2
	b.eq	LBB2_137
; %bb.154:                              ;   in Loop: Header=BB2_138 Depth=3
	ldrh	w4, [x30, x8, lsl #1]
	lsl	w23, w4, #16
	and	w4, w4, #0x7fff
	orr	w27, w23, #0x400000
	cmp	w4, w1
	csel	w4, w27, w23, hi
	fmov	s3, w4
	cmp	x2, #2
	b.lt	LBB2_163
; %bb.155:                              ;   in Loop: Header=BB2_138 Depth=3
	fmov	s1, s14
	ldr	s5, [x22, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #384]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #384]                 ; 4-byte Folded Spill
	cmp	x2, #2
	b.eq	LBB2_162
; %bb.156:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	s5, [x21, x8, lsl #2]
	fmul	s5, s5, s3
	fadd	s21, s21, s5
	cmp	x2, #3
	b.eq	LBB2_162
; %bb.157:                              ;   in Loop: Header=BB2_138 Depth=3
	str	s21, [sp, #124]                 ; 4-byte Folded Spill
	ldr	x4, [sp, #240]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #292]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #292]                 ; 4-byte Folded Spill
	cmp	x2, #4
	b.ne	LBB2_159
; %bb.158:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	s21, [sp, #124]                 ; 4-byte Folded Reload
	b	LBB2_162
LBB2_159:                               ;   in Loop: Header=BB2_138 Depth=3
	fmov	s6, s4
	fmov	s4, s15
	fmov	s14, s17
	ldr	x4, [sp, #152]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s15, [sp, #284]                 ; 4-byte Folded Reload
	fadd	s15, s15, s5
	str	s15, [sp, #284]                 ; 4-byte Folded Spill
	cmp	x2, #5
	b.eq	LBB2_161
; %bb.160:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	x4, [sp, #144]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s5, s5, s3
	fmov	s15, s11
	ldr	s11, [sp, #272]                 ; 4-byte Folded Reload
	fadd	s11, s11, s5
	str	s11, [sp, #272]                 ; 4-byte Folded Spill
	fmov	s11, s15
LBB2_161:                               ;   in Loop: Header=BB2_138 Depth=3
	fmov	s17, s14
	ldr	s21, [sp, #124]                 ; 4-byte Folded Reload
	fmov	s15, s4
	fmov	s4, s6
	movi.4h	v6, #124, lsl #8
LBB2_162:                               ;   in Loop: Header=BB2_138 Depth=3
	fmov	s14, s1
LBB2_163:                               ;   in Loop: Header=BB2_138 Depth=3
	ldr	s5, [x25, x8, lsl #2]
	fmul	s3, s5, s3
	ldr	s1, [sp, #400]                  ; 4-byte Folded Reload
	fadd	s1, s1, s3
	str	s1, [sp, #400]                  ; 4-byte Folded Spill
	cmp	x10, #3
	b.eq	LBB2_137
; %bb.164:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	x4, [sp, #232]                  ; 8-byte Folded Reload
	ldrh	w4, [x4, x8, lsl #1]
	lsl	w23, w4, #16
	and	w4, w4, #0x7fff
	orr	w27, w23, #0x400000
	cmp	w4, w1
	csel	w4, w27, w23, hi
	fmov	s3, w4
	ldr	s5, [x25, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s1, [sp, #352]                  ; 4-byte Folded Reload
	fadd	s1, s1, s5
	str	s1, [sp, #352]                  ; 4-byte Folded Spill
	cmp	x2, #2
	b.lt	LBB2_137
; %bb.165:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	s5, [x22, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s1, [sp, #304]                  ; 4-byte Folded Reload
	fadd	s1, s1, s5
	str	s1, [sp, #304]                  ; 4-byte Folded Spill
	cmp	x2, #2
	b.eq	LBB2_137
; %bb.166:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	s5, [x21, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s1, [sp, #288]                  ; 4-byte Folded Reload
	fadd	s1, s1, s5
	str	s1, [sp, #288]                  ; 4-byte Folded Spill
	cmp	x2, #3
	b.eq	LBB2_137
; %bb.167:                              ;   in Loop: Header=BB2_138 Depth=3
	str	s15, [sp, #100]                 ; 4-byte Folded Spill
	fmov	s15, s21
	str	s17, [sp, #124]                 ; 4-byte Folded Spill
	ldr	x4, [sp, #240]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s21, [sp, #276]                 ; 4-byte Folded Reload
	fadd	s21, s21, s5
	str	s21, [sp, #276]                 ; 4-byte Folded Spill
	cmp	x2, #4
	b.eq	LBB2_136
; %bb.168:                              ;   in Loop: Header=BB2_138 Depth=3
	fmov	s1, s14
	ldr	x4, [sp, #152]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s5, s5, s3
	ldr	s14, [sp, #268]                 ; 4-byte Folded Reload
	fadd	s14, s14, s5
	str	s14, [sp, #268]                 ; 4-byte Folded Spill
	cmp	x2, #5
	fmov	s21, s15
	b.eq	LBB2_170
; %bb.169:                              ;   in Loop: Header=BB2_138 Depth=3
	ldr	x4, [sp, #144]                  ; 8-byte Folded Reload
	ldr	s5, [x4, x8, lsl #2]
	fmul	s3, s5, s3
	ldr	s5, [sp, #252]                  ; 4-byte Folded Reload
	fadd	s5, s5, s3
	str	s5, [sp, #252]                  ; 4-byte Folded Spill
LBB2_170:                               ;   in Loop: Header=BB2_138 Depth=3
	ldr	s17, [sp, #124]                 ; 4-byte Folded Reload
	ldr	s15, [sp, #100]                 ; 4-byte Folded Reload
	fmov	s14, s1
	b	LBB2_137
LBB2_171:                               ;   in Loop: Header=BB2_6 Depth=2
	cmp	x13, #1
	b.lt	LBB2_5
; %bb.172:                              ;   in Loop: Header=BB2_6 Depth=2
	cmp	x6, #1
	b.lt	LBB2_5
; %bb.173:                              ;   in Loop: Header=BB2_6 Depth=2
	ldp	x8, x12, [sp, #168]             ; 16-byte Folded Reload
	mul	x8, x26, x8
	add	x8, x12, x8, lsl #2
	ldr	q2, [sp, #448]                  ; 16-byte Folded Reload
	faddp.4s	v2, v2, v2
	faddp.2s	s2, v2
	fadd	s0, s2, s0
	str	s0, [x8]
	cmp	x10, #2
	b.lt	LBB2_177
; %bb.174:                              ;   in Loop: Header=BB2_6 Depth=2
	ldr	q0, [sp, #432]                  ; 16-byte Folded Reload
	faddp.4s	v0, v0, v0
	faddp.2s	s0, v0
	ldr	s1, [sp, #464]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #4]
	cmp	x10, #2
	b.eq	LBB2_177
; %bb.175:                              ;   in Loop: Header=BB2_6 Depth=2
	ldr	q0, [sp, #480]                  ; 16-byte Folded Reload
	faddp.4s	v0, v0, v0
	faddp.2s	s0, v0
	ldr	s1, [sp, #400]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #8]
	cmp	x10, #3
	b.eq	LBB2_177
; %bb.176:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v10, v10
	faddp.2s	s0, v0
	ldr	s1, [sp, #352]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #12]
LBB2_177:                               ;   in Loop: Header=BB2_6 Depth=2
	cmp	x2, #2
	b.lt	LBB2_5
; %bb.178:                              ;   in Loop: Header=BB2_6 Depth=2
	orr	x8, x26, #0x1
	ldp	x13, x12, [sp, #168]            ; 16-byte Folded Reload
	mul	x8, x8, x13
	add	x8, x12, x8, lsl #2
	faddp.4s	v0, v18, v18
	faddp.2s	s0, v0
	fadd	s0, s0, s11
	str	s0, [x8]
	cmp	x10, #2
	b.lt	LBB2_182
; %bb.179:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v12, v12
	faddp.2s	s0, v0
	fadd	s0, s0, s14
	str	s0, [x8, #4]
	cmp	x10, #2
	b.eq	LBB2_182
; %bb.180:                              ;   in Loop: Header=BB2_6 Depth=2
	ldr	q0, [sp, #416]                  ; 16-byte Folded Reload
	faddp.4s	v0, v0, v0
	faddp.2s	s0, v0
	ldr	s2, [sp, #384]                  ; 4-byte Folded Reload
	fadd	s0, s0, s2
	str	s0, [x8, #8]
	cmp	x10, #3
	b.eq	LBB2_182
; %bb.181:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v8, v8
	faddp.2s	s0, v0
	ldr	s1, [sp, #304]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #12]
LBB2_182:                               ;   in Loop: Header=BB2_6 Depth=2
	cmp	x2, #2
	b.eq	LBB2_5
; %bb.183:                              ;   in Loop: Header=BB2_6 Depth=2
	add	x8, x26, #2
	ldp	x13, x12, [sp, #168]            ; 16-byte Folded Reload
	mul	x8, x8, x13
	add	x8, x12, x8, lsl #2
	faddp.4s	v0, v20, v20
	faddp.2s	s0, v0
	fadd	s0, s0, s4
	str	s0, [x8]
	cmp	x10, #2
	b.lt	LBB2_187
; %bb.184:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v9, v9
	faddp.2s	s0, v0
	fadd	s0, s0, s15
	str	s0, [x8, #4]
	cmp	x10, #2
	b.eq	LBB2_187
; %bb.185:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v30, v30
	faddp.2s	s0, v0
	fadd	s0, s0, s21
	str	s0, [x8, #8]
	cmp	x10, #3
	b.eq	LBB2_187
; %bb.186:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v31, v31
	faddp.2s	s0, v0
	ldr	s1, [sp, #288]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #12]
LBB2_187:                               ;   in Loop: Header=BB2_6 Depth=2
	cmp	x2, #3
	b.eq	LBB2_5
; %bb.188:                              ;   in Loop: Header=BB2_6 Depth=2
	add	x8, x26, #3
	ldp	x13, x12, [sp, #168]            ; 16-byte Folded Reload
	mul	x8, x8, x13
	add	x8, x12, x8, lsl #2
	faddp.4s	v0, v29, v29
	faddp.2s	s0, v0
	fadd	s0, s0, s17
	str	s0, [x8]
	cmp	x10, #2
	b.lt	LBB2_192
; %bb.189:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v19, v19
	faddp.2s	s0, v0
	ldr	s1, [sp, #308]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #4]
	cmp	x10, #2
	b.eq	LBB2_192
; %bb.190:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v27, v27
	faddp.2s	s0, v0
	ldr	s1, [sp, #292]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #8]
	cmp	x10, #3
	b.eq	LBB2_192
; %bb.191:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v26, v26
	faddp.2s	s0, v0
	ldr	s1, [sp, #276]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #12]
LBB2_192:                               ;   in Loop: Header=BB2_6 Depth=2
	cmp	x2, #4
	b.eq	LBB2_5
; %bb.193:                              ;   in Loop: Header=BB2_6 Depth=2
	add	x8, x26, #4
	ldp	x13, x12, [sp, #168]            ; 16-byte Folded Reload
	mul	x8, x8, x13
	add	x8, x12, x8, lsl #2
	faddp.4s	v0, v25, v25
	faddp.2s	s0, v0
	ldr	s1, [sp, #320]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8]
	cmp	x10, #2
	b.lt	LBB2_197
; %bb.194:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v24, v24
	faddp.2s	s0, v0
	ldr	s1, [sp, #300]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #4]
	cmp	x10, #2
	b.eq	LBB2_197
; %bb.195:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v22, v22
	faddp.2s	s0, v0
	ldr	s1, [sp, #284]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #8]
	cmp	x10, #3
	b.eq	LBB2_197
; %bb.196:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v16, v16
	faddp.2s	s0, v0
	ldr	s1, [sp, #268]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #12]
LBB2_197:                               ;   in Loop: Header=BB2_6 Depth=2
	cmp	x2, #5
	b.eq	LBB2_5
; %bb.198:                              ;   in Loop: Header=BB2_6 Depth=2
	add	x8, x26, #5
	ldp	x13, x12, [sp, #168]            ; 16-byte Folded Reload
	mul	x8, x8, x13
	add	x8, x12, x8, lsl #2
	faddp.4s	v0, v28, v28
	faddp.2s	s0, v0
	ldr	s1, [sp, #296]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8]
	cmp	x10, #2
	b.lt	LBB2_5
; %bb.199:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v23, v23
	faddp.2s	s0, v0
	ldr	s1, [sp, #280]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #4]
	cmp	x10, #2
	b.eq	LBB2_5
; %bb.200:                              ;   in Loop: Header=BB2_6 Depth=2
	ldr	q0, [sp, #208]                  ; 16-byte Folded Reload
	faddp.4s	v0, v0, v0
	faddp.2s	s0, v0
	ldr	s1, [sp, #272]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #8]
	cmp	x10, #3
	b.eq	LBB2_5
; %bb.201:                              ;   in Loop: Header=BB2_6 Depth=2
	faddp.4s	v0, v7, v7
	faddp.2s	s0, v0
	ldr	s1, [sp, #252]                  ; 4-byte Folded Reload
	fadd	s0, s0, s1
	str	s0, [x8, #12]
	b	LBB2_5
LBB2_202:
	add	sp, sp, #496
	ldp	x29, x30, [sp, #144]            ; 16-byte Folded Reload
	ldp	x20, x19, [sp, #128]            ; 16-byte Folded Reload
	ldp	x22, x21, [sp, #112]            ; 16-byte Folded Reload
	ldp	x24, x23, [sp, #96]             ; 16-byte Folded Reload
	ldp	x26, x25, [sp, #80]             ; 16-byte Folded Reload
	ldp	x28, x27, [sp, #64]             ; 16-byte Folded Reload
	ldp	d9, d8, [sp, #48]               ; 16-byte Folded Reload
	ldp	d11, d10, [sp, #32]             ; 16-byte Folded Reload
	ldp	d13, d12, [sp, #16]             ; 16-byte Folded Reload
	ldp	d15, d14, [sp], #160            ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
.subsections_via_symbols
