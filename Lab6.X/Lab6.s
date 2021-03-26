; Archivo:	Lab4.s
; Dispositivo:	PIC16F887
; Autor:	Julio Avila
; Compilador:	pic-as (v2.30), MPLABX V5.45
;
; Programa:	Contador y Displays
; Hardware:	2 Display 7 segmentos, leds y pushbottons
;
; Creado: 23 mar, 2021
; Última modificación: 24 mar, 2021
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
    movwf	TMR2
    bcf		TMR2IF
    endm
    
    
PSECT udata_bank0   
  BAND:         DS 1  
  var:		DS 2
    
;variables
PSECT udata_shr
  W_TEMP:	DS 1	    
  STATUS_TEMP:  DS 1

PSECT resVect, class=CODE, abs, delta=2
;-----------vector reset--------------;
ORG 00h     ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main

    
PSECT code, delta=2, abs
ORG 100h    ; posicion para le codigo
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
   BANKSEL	T1CON
   bcf		TMR1CS
   bsf		T1CKPS0
   bsf		T1CKPS1
   bcf		T1CON, 3    ; TMR1 con 8 de prescaler y con el oscilador interno
   
   BANKSEL	OPTION_REG
   bsf		OPTION_REG, 0
   bsf		INTEDG
   bcf		T0CS	    ; TMR0 con 16 de prescaler
   bcf		T0SE
   bcf		PSA
   bcf		PS0
   bsf		PS1
   bsf		PS2

   BANKSEL	T2CON
   movlw	0xFF	    ; TMR2 con 16 de postscaler, 16 prescaler
   movwf	T2CON
   
   BANKSEL	OSCCON
   bcf		OSCCON, 3   ; Oscilador interno a 500Khz
   bsf		OSCCON, 4
   bsf		OSCCON, 5
   bcf		OSCCON, 6

   BANKSEL	ANSEL	    ; unicamente puertos digitales
   clrf		ANSEL
   clrf		ANSELH
   
   BANKSEL	TRISA
   movlw	11111110B
   movwf	TRISB	    ; Solo el primer pin se usará como output
   movlw	10000000B
   movwf	TRISC	    ; Solo el último pin no se usa, los demas son del
   movlw	11111100B   ; display
   movwf	TRISD	    ; Los dos primeros pines son del multiplexado
   
   BANKSEL	PORTA	    ; iniciar todo en 0
   clrf		PORTB
   clrf		PORTC
   clrf		PORTD
   clrf		var
   BANKSEL	T1CON
   bsf		T1CON, 0
   ;clrf		BAND
   
   
loop:
    BANKSEL	INTCON
    btfsc	T0IF	    ; Se verifica en ambos casos que se cumpla el 
    call	disp1	    ; overflow del tmr0 para pasar el valor al PORTC
    BANKSEL	INTCON	    ; y hacer el multiplexado
    btfsc	T0IF
    call	disp2	    
    BANKSEL	PIR1
    btfsc	TMR1IF	    ; Se verifica el overflow del tmr1 para incrementar
    call	inc_var	    ; el valor de la variable
    btfsc	TMR2IF
    call	led_off
    goto	loop
    
   
disp1:
    BANKSEL	PORTC
    ;btfsc	BAND, 0
    ;goto	$+7
    clrf	PORTC	    ; Primero se limpia todo el puerto para no cruzar valores
    movf	var, 0
    andlw	00001111B   ; and para solo usar los primeros bits
    call	tabla_	    ; traslado de datos a la tabla
    BANKSEL	PORTC
    movwf	PORTC	    ; Valor numérico al puerto C
    bsf		PORTD, 1    ; Multiplexado
    bcf		PORTD, 0
    reset_TMR0		    ; En ambos casos se reinicia el tmr0
    return
    
disp2:
    BANKSEL	PORTC
    ;btfsc	BAND, 0
    ;goto	$+7
    clrf	PORTC
    swapf	var, 0	    ; swap para usar los otros bits
    andlw	00001111B
    call	tabla_
    BANKSEL	PORTC
    movwf	PORTC
    bsf		PORTD, 0
    bcf		PORTD, 1
    reset_TMR0
    return
    
inc_var:
    incf	var	    ; Incremento de la variable y reinicio del TMR1
    reset_TMR1
    return

    
led_off:
    BANKSEL	PORTB
    movlw	1	    ; xor con 1 funciona como NOT, para que el valor del
    xorwf	PORTB, 1    ; puerto B sea el opuesto.
    ;movlw	1
    ;xorwf	BAND, 1
    ;clrf	PORTC
    reset_TMR2
    return
    
END
    