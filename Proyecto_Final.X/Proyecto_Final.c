/*
 * File:   Proyecto_Final.c
 * Author: swimm
 *
 * Created on 11 de mayo de 2021, 09:40 AM
 */
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF       // Power-up Timer Enable bit (PWRT enabled)
#pragma config MCLRE = ON      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = ON      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = ON       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = ON      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)
#define _XTAL_FREQ 8000000
#define __delay_us(x) _delay((unsigned long)((x)*(_XTAL_FREQ/4000000.0)))


#include <xc.h>

int reg1, reg2, n, modo, cejas, ojos, boca, LED0, LED1;
char word[]= "lol";

void my_delay(n){                       //Función de delay para valores
    while(n--){                         //variables
        __delay_us(1);
    }
}

void UART_write(unsigned char* word){   //Función que transmite datos
    while (*word != 0){                 //Verifica que el puntero aumente
        TXREG = (*word);                //Envía el caracter que toca de la cadena
        while(!TXSTAbits.TRMT);         //Espera a que se haya enviado el dato
        word++;                         //Aumenta el apuntador para ir al
    }                                   //siguente caracter
    return;
}

void EEPROM_write(int data, int address){
    EEADR = address;                    //Rutina para guardar datos, en
    EEDAT = data;                   //la EEPROM recibiendo la dirección
    EECON1bits.EEPGD = 0;           //y el dato, siguiendo l rutina para
    EECON1bits.WREN = 1;            //asegurar la escritura y apagando las
    INTCONbits.GIE = 0;             //interrupciones
    EECON2 = 0x55;
    EECON2 = 0xAA;
    EECON1bits.WR = 1;
    while(PIR2bits.EEIF==0);    //Espera a que haya termiando
    EEIF = 0;
    EECON1bits.WREN = 0;
    INTCONbits.GIE = 1;
}

int EEPROM_read(int address){
    EEADR = address;            //Rutina que recibe la dirección de la
    EECON1bits.EEPGD = 0;       //EEPROM para leer y regresar
    EECON1bits.RD = 1;
    return EEDAT;
}

void __interrupt()isr(void){
    if(T0IF){
        PORTCbits.RC0 = 1;      //Bit banging enciendo manualmente
        my_delay(100+ojos*100/256);//los pines con un tiempo mínimo de
        PORTCbits.RC0 = 0;//1ms y máximo de 2ms dependiendo del registro
        PORTCbits.RC3 = 1;
        my_delay(100+cejas*100/256);
        PORTCbits.RC3 = 0;
        PORTCbits.RC4 = 1;
        my_delay(100+cejas*100/256);
        PORTCbits.RC4 = 0;
        PORTCbits.RC5 = 1;
        my_delay(100+boca*100/256);
        PORTCbits.RC5 = 0;
        TMR0 = 225;
        T0IF = 0;
    }
    if (RBIF){
        if(RB1==0){             //Los push de los pines 1 y 2 cambiaban
            modo = 1;           //el modo para leer o guardar en la EEPROM
        }
        else if(RB2==0){
            if (modo==0){
                modo = 2;
            }
            else if(modo == 2){
                modo = 0;
            }
        }
        else if(RB3 == 0){  //El pin 3 tenía el push del joystick que abría
            if(modo == 0){//o cerraba la boca
                boca = 128;
            }
        }
        else if(RB3 == 1){
            if(modo == 0){
                boca = 0;
            }
        }
        RBIF = 0;
    }
    if(RCIF){
        if(RCREG=='1'){
            PORTDbits.RD0=~PORTDbits.RD0;   //La consola controlaba el encendido
            LED0 = !LED0;               //y apagado de los ojos con 1 y 2
        }
        else if(RCREG=='2'){
            PORTDbits.RD1=~PORTDbits.RD1;
            LED1 = !LED1;
        }
        else if(RCREG=='0'){            //con 0 se entra al modo de control con 
            if(modo==3){                //el teclado
                PORTDbits.RD4 = 0;
                modo = 1;
            }
            else if(modo!=3){
                PORTDbits.RD4 = 1;
                modo = 3;
            }  
        }
        else if((RCREG=='w') && (modo==3)){//las teclas controlan los motores
                ojos=255;                   //solo estando en el modo 3
        }
        else if((RCREG=='s') && (modo==3)){
                ojos=0;
        }
        else if((RCREG=='a') && (modo==3)){
                cejas=255;
        }
        else if((RCREG=='d') && (modo==3)){
                cejas=0;
        }
        else if((RCREG==32) && (modo==3) && (boca==128)){
                boca=0;
        }
        else if((RCREG==32) && (modo==3) && (boca==0)){
                boca=128;
        }
    }
    if (ADIF){
        if(ADCON0bits.CHS == 2){
            CCPR1L = (ADRESH>>1);       //Canal 2 controla el PWM del DC
        }
        else if((ADCON0bits.CHS == 1) && (modo==0)){ //Canal 1 y 2 ojos y cejas
            cejas = ADRESH;
        }
        else if((ADCON0bits.CHS == 0) && (modo == 0)){
            //reg1 = ((2*ADRESH)/255);
            //reg2 = 2-reg1;
            ojos = ADRESH;
        }
        PIR1bits.ADIF = 0;
    }
    if(EEIF){
        EEIF = 0;
    }
    if(TMR2IF){
        TMR2IF = 0;
    }
    return;
}

void main(void) {
    ANSEL = 0B00000111;         //3 entradas analógicas
    ANSELH = 0x00;
    
    TRISA = 0B00000111;
    TRISB = 0B00001110;
    TRISC = 0B11000000;
    TRISD = 0x00;
    
    PORTD = 0B00000011;
    LED0 = 1;
    LED1 = 1;
    
    IOCBbits.IOCB = 0B00001110;
    
    OSCCONbits.IRCF = 0B111;    //Oscilador a 8MHz
    OSCCONbits.OSTS = 0;
    OSCCONbits.SCS = 1;
    
    OPTION_REGbits.nRBPU = 0;   //Pull ups PORTB
    OPTION_REGbits.T0CS = 0;    //TMR0 a 0.01ms
    OPTION_REGbits.T0SE = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS = 0B110;
    TMR0 = 225;
    
    PIE1bits.ADIE = 1;          //Interrupciones ADC y EEPROM
    PIE2bits.EEIE = 1;
    
    ADCON0bits.ADCS = 0B10;     
    ADCON0bits.ADON = 1;
    ADCON1bits.ADFM = 0;        //Justificado a la izquierda
    ADCON1bits.VCFG0 = 0;       //VSS y VDD como pines de referencia
    ADCON1bits.VCFG1 = 0;
    ADCON0bits.GO_DONE = 0;
    ADCON0bits.CHS = 0;        //Comienza con el canal 0
    
    SPBRG = 12;                 //Valor para 9600 de baudrate
    TXSTAbits.SYNC = 0;         //Comunicación asíncrona
    RCSTAbits.SPEN = 1;
    TXSTAbits.TX9 = 0;          //Solo de 8 bits
    TXSTAbits.TXEN = 1;
    
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;
        
    CCP1CONbits.P1M = 0B00;     //Módulo CCP como PWM, solo uno se usará
    CCP1CONbits.CCP1M = 0B1100;
    TRISCbits.TRISC2 = 1;
    PR2 = 246;                  //Valor del TMR2 para el periodo
    CCPR1L = 0x0F;
    CCP1CONbits.DC1B = 0;
    
    T2CONbits.TOUTPS = 0;       //Configuración del TMR2
    T2CONbits.T2CKPS = 0B11;
    T2CONbits.TMR2ON = 1;
    PIR1bits.TMR2IF = 0;
    
    while(PIR1bits.TMR2IF==0);  //Se espera a un ciclo para empezar
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;
    
    PIE1bits.RCIE = 1;
    PIE1bits.TXIE = 0;
    INTCONbits.RBIE = 1;        //Interrupciones del PORTB
    INTCONbits.PEIE = 1;        //Se activan todas las interrupciones
    INTCONbits.INTE = 1;
    //INTCONbits.T0IE = 1;
    INTCONbits.GIE = 1;
    
    PIE2bits.EEIE = 1;
    RBIF = 0;
    PIR1bits.TXIF = 0;
    PIR1bits.RCIF = 0;
    ADCON0bits.GO = 1;
    modo = 0;
      
    
    while(1){
        UART_write("Presione 1 o 2 para controlar los LEDs \r \0");
        __delay_ms(50);//Mensaje inicial a la consola
        UART_write("O presione 0 para controlar los motores \r \0"); 
        
        while(modo==0){
            if(ADCON0bits.GO == 0){         //Cambio constante de canal
                if(ADCON0bits.CHS == 0){    //solo en el modo 0
                    ADCON0bits.CHS = 1;
                }
                else if(ADCON0bits.CHS == 1){
                    ADCON0bits.CHS = 2;
                }
                else if(ADCON0bits.CHS == 2){
                    ADCON0bits.CHS = 0;
                }
                __delay_us(50);
                ADCON0bits.GO = 1;
            }
        }
        
        
        if(modo == 1){                  //Modo 1 llama a la rutina para
            PORTDbits.RD2 = 1;          //escribir a la EEPROM guardando
            EEPROM_write(0x00, cejas);  //las posiciones de los motores
            EEPROM_write(0x01, ojos);
            EEPROM_write(0x02, boca);
            EEPROM_write(0x03, LED0);
            EEPROM_write(0x04, LED1);
            __delay_ms(500);
            PORTDbits.RD2 = 0;
            modo = 0;
        }
        if(modo==2){
            PORTDbits.RD3 = 1;
            cejas = EEPROM_read(0x00);          //Modo 2 llama los valores
            ojos = EEPROM_read(0x01);           //guardados y se queda ahí
            boca = EEPROM_read(0x02);           //hasta que con el push se cambie
            PORTDbits.RD0 = EEPROM_read(0x03);
            PORTDbits.RD1 = EEPROM_read(0x04);
            while(modo==2);
            PORTDbits.RD3 = 0;
            
        }
        
        if(modo==3){
            UART_write("Presione wasd para controlar motores \r \0");
            while(modo==3); //Entra al modo 3, da el mensaje y lo demas funciona
        }                   //con interrupciones
    }
}

