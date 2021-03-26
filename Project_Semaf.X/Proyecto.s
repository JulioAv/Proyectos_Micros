; Archivo:	Proyecto.s
; Dispositivo:	PIC16F887
; Autor:	Julio Avila
; Compilador:	pic-as (v2.30), MPLABX V5.45
;
; Programa:	Sistema de Semáforos
; Hardware:	6 displays, 3 pushbuttons, 12 LEDs, transistores NPN
;
; Creado: 16 mar, 2021
; Última modificación: 22 mar, 2021
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

PSECT udata_bank0
   int_B:   DS 1
   cont_1:  DS 1
   
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
    return
    
isr:
    btfsc   RBIF
    call    int_iocb
    btfss   T0IF
    call    T0_int
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
int_iocb:
    BANKSEL PORTB
    btfsc   PORTB, 0
    bsf	    int_B, 0
    btfsc   PORTB, 1
    bsf	    int_B, 1
    btfsc   PORTB, 2
    bsf	    int_B, 2
    
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
    
    BANKSEL	OPTION_REG
    bcf		OPTION_REG, 7
    bcf		T0CS
    bcf		T0SE
    bcf		PSA
    ;bcf		PS2
    ;bcf		PS1
    ;bcf		PS0
    BANKSEL	TMR0	    
    ;movlw	100		; Valor de TMR0 para 5ms
    ;movwf	TMR0
    
    BANKSEL	T1CON
    bcf		TMR1GE
    bsf		T1CKPS1
    bsf		T1CKPS0
    bcf		T1OSCEN
    bcf		TMR1CS
    
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
    
    BANKSEL	PORTA
    clrf	PORTA		; iniciar todo en 0
    clrf	PORTB
    clrf	PORTC
    clrf	PORTD
    
 ;---------------------------------------;
 
 loop:
    btfsc	int_B, 0
    call	modo_1
    movf	cont_1, 0
    movwf	disp_1
    call	modo_2
    call	modo_3
    call	modo_4
    call	modo_5
    goto	loop
    
 modo_1:
    
    goto	$-
    return
    
 modo_2:
    clrf	cont_1
    btfsc	int_B, 1
    incf	cont_1
    btfsc	int_B, 2
    decf	cont_1
    btfss	int_B, 0
    goto	$-
    return
    
 modo_3:
    
    return
    
 modo_4:
    
    return
    
 modo_5:
    
    return
    
 