; Archivo:	Proyecto.s
; Dispositivo:	PIC16F887
; Autor:	Julio Avila
; Compilador:	pic-as (v2.30), MPLABX V5.45
;
; Programa:	Sistema de Semáforos
; Hardware:	6 displays, 3 pushbuttons, 12 LEDs, transistores NPN
;
; Creado: 16 mar, 2021
; Última modificación: 2 abr, 2021
;
; configuration word 1
    
PROCESSOR 16F887
    #include <xc.inc>
    
  CONFIG FOSC=INTRC_NOCLKOUT	//oscilador interno
  CONFIG WDTE=OFF   // WDT disabled (reinicio repetitivo de pic)
  CONFIG PWRTE=ON   // PWRT enabled (espera de 72ms al iniciar)
  CONFIG MCLRE=OFF  // El pin de MCLR se utiliza como I/O
  CONFIG CP=OFF    //Sin protección de código
  CONFIG CPD=OFF   //Sin protección de datos
  
  CONFIG BOREN=OFF  // Sin reinicio cuando el voltaje de alimentación baja de 4V
  CONFIG IESO=OFF   //Reinicio sin cambio de reloj de interno a externo
  CONFIG FCMEN=OFF  //Cambio de reloj externo a interno en caso de fallo
  CONFIG LVP=ON	    //programación en bajo voltaje permitida
  
; configuration word 2
   CONFIG WRT=OFF  //Protección de autoescritura por el programa desactivada
   CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V, (BOR21V-2.1V)

reset_TMR0 macro
    BANKSEL	TMR0
    movlw	240
    movwf	TMR0
    bcf		T0IF
    endm
    
reset_TMR1 macro
    BANKSEL	TMR0
    movlw	0xC2
    movwf	TMR1H
    movlw	0xF7
    movwf	TMR1L
    bcf		TMR1IF
    endm

reset_TMR2 macro
    BANKSEL	PIR1
    movlw	122
    movwf	PR2
    bcf		TMR2IF
    endm   
   
PSECT udata_bank0
   int_B:   DS 1	; Indicador del cambio de estado o de selección
   T2FLAG:  DS 1
   disp:    DS 1	; Indicador del siguiente display a multiplexar
   sem:	    DS 1	; el bit 3 enciende la luz titilante y el 4 el TMR1
   decena: DS 1
   div1:    DS 1
   unidad:  DS 1
   temp_1:  DS 2	; tiempo temporal a usar en el semáforo
   temp_2:  DS 2
   temp_3:  DS 2
   cont_01:  DS 2	; valor mostrado en el semáforo
   cont_23:  DS 2
   cont_45:  DS 2
   cont_67:  DS 2
   via_1:   DS 2	; tiempo total que dura el semáforo en paso
   via_2:   DS 2
   via_3:   DS 2
   
   
PSECT udata_shr
 W_TEMP: DS 1
 STATUS_TEMP: DS 1
    
PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset---------------;
ORG 00h	    ;Posición 0000h para el reset
resetVect:
    PAGESEL main
    goto main
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h	    ;posición 0004h para las interrupciones

push:
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP
    
isr:
    btfsc   RBIF
    call    int_iocb
    btfsc   T0IF
    call    int_tmr0
    btfsc   TMR1IF
    call    int_tmr1
    btfsc   TMR2IF
    call    int_tmr2
    
pop:
    BANKSEL STATUS
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
int_iocb:
    BANKSEL PORTB
    btfss   PORTB, 0
    bsf	    int_B, 0
    btfss   PORTB, 1
    bsf	    int_B, 1
    btfss   PORTB, 2
    bsf	    int_B, 2
    bcf	    RBIF
    return
    
int_tmr0:
    reset_TMR0
    btfsc   disp, 7
    call    disp7
    ;----------------
    btfsc   disp, 6
    call    disp6
    ;------------------
    btfsc   disp, 5
    call    disp5
    ;---------------
    btfsc   disp, 4
    call    disp4
    ;----------------
    btfsc   disp, 3
    call    disp3
    ;----------------
    btfsc   disp, 2
    call    disp2
    ;------------------
    btfsc   disp, 1
    call    disp1
    ;-----------------
    btfsc   disp, 0
    call    disp0
    return
    
int_tmr1:
    call    inc_var
    return
    
int_tmr2:
    btfss   sem, 0
    goto    $+10
    btfsc   T2FLAG, 0
    goto    $+4
    bsf	    T2FLAG, 0
    bcf	    PORTD, 0
    goto    $+5
    btfss   T2FLAG, 0
    goto    $+3
    bcf	    T2FLAG, 0
    bsf	    PORTD, 0
    reset_TMR2
    ;---------------------
    btfss   sem, 1
    goto    $+9
    btfss   T2FLAG, 0
    goto    $+3
    bsf	    PORTD, 1
    bcf	    T2FLAG, 0
    btfsc   T2FLAG, 0
    goto    $+3
    bcf	    PORTD, 1
    bsf	    T2FLAG, 0
    reset_TMR2
    ;----------------------
    btfss   sem, 2
    goto    $+9
    btfss   T2FLAG, 0
    goto    $+3
    bsf	    PORTD, 2
    bcf	    T2FLAG, 0
    btfsc   T2FLAG, 0
    goto    $+3
    bcf	    PORTD, 2
    bsf	    T2FLAG, 0
    reset_TMR2
    return
    
        
PSECT code, delta=2, abs
ORG 100h    ; posición para el codigo
 
tabla_:
    BANKSEL PCLATH
    clrf    PCLATH
    bsf	 PCLATH, 0
    addwf   PCL		    ; El valor del PC se suma con lo que haya en w para
    retlw   00111111B	    ; 0	    ir a la linea respectiva de cada valor
    retlw   00000110B	    ; 1	    El and es para asegurar que el valor que 
    retlw   01011011B	    ; 2	    entre sea unicamente de 4 bits.
    retlw   01001111B	    ; 3	    Con el retlw regresa a al respectivo módulo
    retlw   01100110B	    ; 4	    y lo traslada al puerto A, que es donde
    retlw   01101101B	    ; 5	    está el display.
    retlw   01111101B	    ; 6
    retlw   01000111B	    ; 7
    retlw   01111111B	    ; 8
    retlw   01100111B	    ; 9
    retlw   01110111B	    ; A
    retlw   01111100B	    ; b
    retlw   00111001B	    ; c
    retlw   01011110B	    ; d
    retlw   01111001B	    ; E
    retlw   01110001B	    ; F
    return
    
main:
    BANKSEL	ANSEL
    clrf	ANSEL
    clrf	ANSELH	    ;Solo puertos digitales
    
    BANKSEL	TRISA
    movlw	00h
    movwf	TRISC
    movlw	07h
    movwf	TRISB	    ; Los 3 primeros pines son para los push
    movlw	00h
    movwf	TRISD
    movlw	00h
    movwf	TRISE
    movlw	00h
    movwf	TRISA
    
    BANKSEL	IOCB
    movlw	00000111B
    movwf	IOCB
    
    BANKSEL	OPTION_REG
    bcf		OPTION_REG, 7
    bcf		T0CS
    bcf		T0SE
    bcf		PSA
    bsf		PS2
    bsf		PS1
    bcf		PS0
    BANKSEL	TMR0	    
    movlw	178		; Valor de TMR0 para 5ms
    movwf	TMR0
    
    BANKSEL	T1CON
    bcf		TMR1CS
    bsf		T1CKPS0
    bsf		T1CKPS1
    bcf		T1CON, 3	;TMR1 con prescaler de 8
    
    BANKSEL	T2CON
    movlw	0xFF
    movwf	T2CON
    
    BANKSEL	OSCCON
    bsf		OSCCON, 0
    bcf		OSCCON, 3	    ; Oscilador interno a 500KHz
    bsf		OSCCON, 4
    bsf		OSCCON, 5
    bcf		OSCCON, 6
    
    BANKSEL	INTCON
    bsf		GIE     
    bsf		RBIE		; Interrupciones del puerto B
    bsf		T0IE
    bsf		PEIE
    
    BANKSEL	PIE1
    bsf		TMR1IE
    bsf		TMR2IE
    
    BANKSEL	PORTA
    clrf	PORTA		; iniciar todo en 0
    clrf	PORTB
    clrf	PORTC
    clrf	PORTD
    movlw	0x0A
    movwf	via_1
    movlw	0x0A
    movwf	via_2
    movlw	0x0A
    movwf	via_3
    clrf	cont_01
    clrf	cont_23
    clrf	cont_45
    clrf	cont_67
    clrf	int_B
    clrf	temp_1
    clrf	sem
    clrf	disp
    bsf		disp, 0
    clrf	T2FLAG
    
    BANKSEL	T1CON
    bsf		T1CON, 0
    BANKSEL	T2CON
    bcf		T2CON, 2
    
 ;---------------------------------------;
 
 loop:
    call	temps
    call	modo_1
    call	modo_2
    call	modo_3
    call	modo_4
    call	modo_5
    call	modo_R
    goto	loop
    
 
    
 inc_val:
    BANKSEL	PIR1
    btfsc	TMR1IF	    ; Se verifica el overflow del tmr1 para incrementar
    call	inc_var
    return
 
 temps:
    movlw	0x0A
    movwf	temp_1
    movwf	temp_2
    movwf	temp_3
    return
    
 modo_1:
    BANKSEL	PORTB
    bsf		PORTB, 3
    bcf		PORTB, 4
    bcf		PORTB, 5
    call values
    btfss	int_B, 0
    goto	$-2
    return
    
 modo_2:
    BANKSEL	PORTB
    clrf	PORTD
    bcf		PORTB, 6
    bcf		PORTB, 3
    bsf		PORTB, 4
    bcf		PORTB, 5
    bcf		int_B, 0
    btfsc	int_B, 1
    incf	temp_1
    btfsc	int_B, 2
    decf	temp_1
    movf	temp_1, 0
    sublw	9
    btfss	STATUS, 0
    goto	$+3
    movlw	20
    movwf	temp_1
    movlw	21
    subwf	temp_1, 0
    btfss	STATUS, 0
    goto	$+3
    movlw	10
    movwf	temp_1
    movf	temp_1, 0
    movwf	cont_01
    bcf		int_B, 1
    bcf		int_B, 2
    btfss	int_B, 0
    goto	modo_2
    return
    
 modo_3:
    BANKSEL	PORTB
    bsf		PORTB, 3
    bsf		PORTB, 4
    bcf		PORTB, 5
    bcf		int_B, 0
    btfsc	int_B, 1
    incf	temp_2
    btfsc	int_B, 2
    decf	temp_2
    movf	temp_2, 0
    sublw	9
    btfss	STATUS, 0
    goto	$+3
    movlw	20
    movwf	temp_2
    movlw	21
    subwf	temp_2, 0
    btfss	STATUS, 0
    goto	$+3
    movlw	10
    movwf	temp_2
    movf	temp_2, 0
    movwf	cont_01
    bcf		int_B, 1
    bcf		int_B, 2
    btfss	int_B, 0
    goto	modo_3
    return
    
 modo_4:
    BANKSEL	PORTB
    bcf		PORTB, 3
    bcf		PORTB, 4
    bsf		PORTB, 5
    bcf		int_B, 0
    btfsc	int_B, 1
    incf	temp_3
    btfsc	int_B, 2
    decf	temp_3
    movf	temp_3, 0
    sublw	9
    btfss	STATUS, 0
    goto	$+3
    movlw	20
    movwf	temp_3
    movlw	21
    subwf	temp_3, 0
    btfss	STATUS, 0
    goto	$+3
    movlw	10
    movwf	temp_3
    movf	temp_3, 0
    movwf	cont_01
    bcf		int_B, 1
    bcf		int_B, 2
    btfss	int_B, 0
    goto	modo_4
    return
    
 modo_5:
    BANKSEL	PORTB
    bsf		PORTB, 3
    bcf		PORTB, 4
    bsf		PORTB, 5
    bcf		int_B, 0
    btfss	int_B, 1
    goto	$+8
    movf	temp_1, 0
    movwf	via_1
    movf	temp_2, 0
    movwf	via_2
    movf	temp_3, 0
    movwf	via_3
    goto	$+6
    btfss	int_B, 2
    goto	$-10
    clrf	temp_1
    clrf	temp_2
    clrf	temp_3
    return
    
 modo_R:
    btfss	TMR1IF
    goto	$-1
    clrf	PORTC
    movlw	0xFF
    movwf	PORTD
    bsf		PORTB, 6
    btfss	TMR1IF
    goto	$-1
    clrf	PORTD
    bcf		PORTB, 6
    return
    
    
 values:
    ;--VIA 1 EN VERDE------
    BANKSEL	T2CON
    bcf		T2CON, 2
    movlw	10000001B
    movwf	PORTD
    bsf		PORTB, 6
    movf	via_1, 0
    movwf	cont_45
    movf	via_1, 0
    addwf	via_2, 0
    movwf	cont_67
    movlw	6
    subwf	via_1, 0
    movwf	cont_23
    movf	cont_23, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3
    movlw	00001001B
    movwf	sem
    BANKSEL	T2CON
    bsf		T2CON, 2
    btfsc	int_B, 0
    goto	modo_2
    movlw	3
    movwf	cont_23
    movf	cont_23, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3
    BANKSEL	T2CON
    bcf		T2CON, 2
    btfsc	int_B, 0
    goto	modo_2
    movlw	10001000B
    movwf	PORTD
    movlw	3
    movwf	cont_23
    movf	cont_23, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3 
    btfsc	int_B, 0
    goto	modo_2
    ;-----VIA 2 EN VERDE--------
    BANKSEL	T2CON
    bcf		T2CON, 2
    movlw	01000010B
    movwf	PORTD
    bsf		PORTB, 6
    movf	via_2, 0
    movwf	cont_67
    movlw	6
    subwf	via_2, 0
    movwf	cont_45
    movf	via_2, 0
    addwf	via_3, 0
    movwf	cont_23
    movf	cont_45, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3
    BANKSEL	T2CON
    bsf		T2CON, 2
    movlw	00001010B
    movwf	sem
    btfsc	int_B, 0
    goto	modo_2
    movlw	3
    movwf	cont_45
    movf	cont_45, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3
    BANKSEL	T2CON
    bcf		T2CON, 2
    btfsc	int_B, 0
    goto	modo_2
    movlw	01010000B
    movwf	PORTD
    movlw	3
    movwf	cont_45
    movf	cont_45, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3 
    btfsc	int_B, 0
    goto	modo_2
    ;-----VIA 3 EN VERDE------
    movlw	11000100B
    movwf	PORTD
    bcf		PORTB, 6
    movf	via_3, 0
    movwf	cont_23
    movlw	6
    subwf	via_3, 0
    movwf	cont_67
    movf	via_3, 0
    addwf	via_1, 0
    movwf	cont_45
    movf	cont_67, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3
    BANKSEL	T2CON
    bsf		T2CON, 2
    movlw	00001100B
    movwf	sem
    btfsc	int_B, 0
    goto	modo_2
    movlw	3
    movwf	cont_67
    movf	cont_67, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3
    BANKSEL	T2CON
    bcf		T2CON, 2
    movlw	11100000B
    movwf	PORTD
    movlw	3
    movwf	cont_67
    movf	cont_67, 0
    sublw	0
    btfss	STATUS, 0
    goto	$-3 
    return
 
 division:
    clrf	unidad
    clrf	decena
    movf	cont_01, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    movf	div1, 0
    movwf	unidad
    return
    
 disp0:	
    clrf	decena
    movf	cont_01, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    addwf	div1, 1
    movf	div1, 0
    movwf	unidad
    BANKSEL	PORTC
    clrf	PORTC	    ; Primero se limpia todo el puerto para no cruzar valores
    movf	unidad, 0
    andlw	00001111B   ; and para solo usar los primeros bits
    call	tabla_	    ; traslado de datos a la tabla
    BANKSEL	PORTC
    movwf	PORTC	    ; Valor numérico al puerto C
    movlw	00000010B
    movwf	PORTA
    clrf	disp
    bsf		disp, 1
    return
    
disp1:
    clrf	decena
    movf	cont_01, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    addwf	div1, 1
    movf	div1, 0
    movwf	unidad
    BANKSEL	PORTC
    clrf	PORTC
    movf	decena, 0	    ; swap para usar los otros bits
    andlw	00001111B
    call	tabla_
    BANKSEL	PORTC
    movwf	PORTC
    movlw	00000001B
    movwf	PORTA
    clrf	disp
    bsf		disp, 2
    return
    
disp2:
    clrf	decena
    movf	cont_23, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    addwf	div1, 1
    movf	div1, 0
    movwf	unidad
    BANKSEL	PORTC
    clrf	PORTC
    movf	unidad, 0	    ; swap para usar los otros bits
    andlw	00001111B
    call	tabla_
    BANKSEL	PORTC
    movwf	PORTC
    movlw	00001000B
    movwf	PORTA
    clrf	disp
    bsf		disp, 3
    return
    
disp3:
    clrf	decena
    movf	cont_23, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    addwf	div1, 1
    movf	div1, 0
    movwf	unidad
    BANKSEL	PORTC
    clrf	PORTC
    movf	decena, 0	    ; swap para usar los otros bits
    andlw	00001111B
    call	tabla_
    BANKSEL	PORTC
    movwf	PORTC
    movlw	00000100B
    movwf	PORTA
    clrf	disp
    bsf		disp, 4
    return
    
disp4:
    clrf	decena
    movf	cont_45, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    addwf	div1, 1
    movf	div1, 0
    movwf	unidad
    BANKSEL	PORTC
    clrf	PORTC
    movf	unidad, 0	    ; swap para usar los otros bits
    andlw	00001111B
    call	tabla_
    BANKSEL	PORTC
    movwf	PORTC
    movlw	00100000B
    movwf	PORTA
    clrf	disp
    bsf		disp, 5
    return
    
disp5:
    clrf	decena
    movf	cont_45, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    addwf	div1, 1
    movf	div1, 0
    movwf	unidad
    BANKSEL	PORTC
    clrf	PORTC
    movf	decena, 0	    ; swap para usar los otros bits
    andlw	00001111B
    call	tabla_
    BANKSEL	PORTC
    movwf	PORTC
    movlw	00010000B
    movwf	PORTA
    clrf	disp
    bsf		disp, 6
    return
    
disp6:
    clrf	decena
    movf	cont_67, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    addwf	div1, 1
    movf	div1, 0
    movwf	unidad
    BANKSEL	PORTC
    clrf	PORTC
    movf	unidad, 0	    ; swap para usar los otros bits
    andlw	00001111B
    call	tabla_
    BANKSEL	PORTC
    movwf	PORTC
    movlw	10000000B
    movwf	PORTA
    clrf	disp
    bsf		disp, 7
    return
    
disp7:
    clrf	decena
    movf	cont_67, 0
    movwf	div1
    movlw	10
    incf	decena
    subwf	div1, 1
    btfsc	STATUS, 0
    goto	$-3
    decf	decena
    addwf	div1, 1
    movf	div1, 0
    movwf	unidad
    BANKSEL	PORTC
    clrf	PORTC
    movf	decena, 0	    ; swap para usar los otros bits
    andlw	00001111B
    call	tabla_
    BANKSEL	PORTC
    movwf	PORTC
    movlw	01000000B
    movwf	PORTA
    clrf	disp
    bsf		disp, 0
    return
    
inc_var:
    reset_TMR1
    decf	cont_23
    decf	cont_45
    decf	cont_67
    return
    
    
END